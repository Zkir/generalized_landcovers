import collections
import re
import os
import tempfile
from datetime import datetime, timedelta
from typing import Any, Dict, Generator, List, Tuple, TextIO, Pattern
from enum import Enum # Import Enum
from more_itertools import peekable
import html

# --- Start of adapted code from make-profiler/make_profiler/parser.py ---
class Tokens(str, Enum):
    target = "target"
    command = "command"
    expression = "expression"


def tokenizer(fd: List[str]) -> Generator[Tuple[Tokens, str], None, None]:
    it = enumerate(fd)

    def glue_multiline(line: str) -> str:
        lines = []
        strip_line = line.strip()
        while strip_line and strip_line[-1] == '\\':
            lines.append(strip_line.rstrip('\\').strip())
            try:
                line_num, line = next(it)
            except StopIteration:
                break # Handle end of file
            strip_line = line.strip()
        lines.append(strip_line.rstrip('\\').strip())
        return ' '.join(lines)

    for line_num, line in it:
        strip_line = line.strip()

        # skip empty lines
        if not strip_line:
            continue

        # skip comments, don't skip docstrings
        if strip_line[0] == '#' and line[:2] != '##':
            continue
        elif line.startswith('\t'): # Check for actual tab character
            yield (Tokens.command, glue_multiline(line))
        elif ':' in line and '=' not in line:
            yield (Tokens.target, glue_multiline(line))
        else:
            yield (Tokens.expression, line.strip(' ;\t'))


def parse_makefile_content(makefile_content: str, is_check_loop: bool = True, loop_check_depth: int = 20) -> List[Tuple[Tokens, Dict[str, Any]]]:
    ast = []

    # This part handles includes, but for simplicity and to avoid file system issues
    # with relative paths and temporary files, we'll assume the makefile_content
    # already has includes resolved or we'll skip include resolution for now.
    # If include resolution is critical, this part needs careful adaptation.
    # For this task, we'll pass the raw makefile content to the tokenizer.
    
    # Simulate TextIO for tokenizer
    class StringTextIO:
        def __init__(self, s):
            self.lines = s.splitlines(keepends=True)
            self.index = 0
        
        def __iter__(self):
            return self
        
        def __next__(self):
            if self.index >= len(self.lines):
                raise StopIteration
            line = self.lines[self.index]
            self.index += 1
            return line

    it = peekable(tokenizer(StringTextIO(makefile_content)))

    def parse_target(token: Tuple[Tokens, str]):
        line = token[1]
        # Regex adapted to be more robust and handle cases where deps/order_deps might be empty
        # Handle '&:' for grouped targets
        match = re.match(
            r'(.+?)\s*(?:&\s*)?:\s*(?:([^|#]+?)\s*)?(?:\|\s*([^#]+?)\s*)?\s*(?:##(.+))?$',
            line
        )
        if not match:
            # Fallback for targets without explicit dependencies or docstrings
            match = re.match(r'(.+?):', line)
            if not match:
                return # Skip if not a valid target line

        targets_str = match.group(1).strip()
        deps_str = match.group(2) if match.group(2) else ''
        order_deps_str = match.group(3) if match.group(3) else ''
        docstring = match.group(4) if match.group(4) else ''

        deps = [p.strip() for p in deps_str.split()] if deps_str else []
        order_deps = [p.strip() for p in order_deps_str.split()] if order_deps_str else []

        body = parse_body()
        
        # Split targets string into individual targets
        for target_name in targets_str.split():
            ast.append((
                token[0],
                {
                    'target': target_name,
                    'deps': [deps, order_deps],
                    'docs': docstring.strip(),
                    'body': body
                })
            )

    def next_belongs_to_target() -> bool:
        try:
            token, _ = it.peek()
            return token == Tokens.command
        except StopIteration:
            return False

    def parse_body() -> List[Tuple[Tokens, str]]:
        body = []
        while next_belongs_to_target():
            body.append(next(it))
        return body

    for token in it:
        if token[0] == Tokens.target:
            parse_target(token)
        else:
            # expression
            ast.append(token)

    return ast


def get_dependencies_influences(ast: List[Tuple[Tokens, Dict[str, Any]]]):
    dependencies = {}
    influences = collections.defaultdict(set)
    order_only = set()
    indirect_influences = collections.defaultdict(set)

    for item_t, item in ast:
        if item_t != Tokens.target:
            continue
        target = item['target']
        deps, order_deps = item['deps']

        if target in ('.PHONY',):
            continue

        dependencies[target] = [deps, order_deps]

        # influences
        influences[target] # Ensure target exists in influences even if it has no direct influences
        for k in deps:
            influences[k].add(target)
        for k in order_deps:
            influences[k]
        order_only.update(order_deps)

    def recurse_indirect_influences(original_target, recurse_target):
        # Avoid infinite recursion for circular dependencies
        if original_target in indirect_influences[recurse_target]:
            return

        indirect_influences[original_target].update(influences[recurse_target])
        for t in influences[recurse_target]:
            recurse_indirect_influences(original_target, t)

    for original_target, targets in influences.items():
        for t in targets:
            recurse_indirect_influences(original_target, t)

    return dependencies, influences, order_only, indirect_influences
# --- End of adapted code from make-profiler/make_profiler/parser.py ---


def parse_profiling_log(log_path):
    """
    Parses the makefile-profiling.log to extract task durations and start times.
    Returns a dictionary where keys are target names and values are dicts
    containing duration and start timestamp.
    If a target appears multiple times, the last entry is used.
    """
    task_data = {}
    try:
        with open(log_path, 'r') as f:
            for line in f:
                # Split into max 5 parts: BUILD_ID, START_TS, DURATION, STATUS, and the rest is TARGET
                parts = line.strip().split(maxsplit=4)
                if len(parts) == 5:
                    try:
                        start_ts = int(parts[1])
                        duration_s = int(parts[2])
                        targets_line = parts[4]
                        
                        # The log can have comma-separated targets for one rule
                        for target_name in targets_line.split(','):
                            target_name = target_name.strip()
                            # The log for 'help' target includes its description.
                            # The makefile parser gets only 'help'.
                            # We need to match what the makefile parser gets.
                            # Let's assume target names don't contain spaces.
                            actual_target = target_name.split()[0]
                            task_data[actual_target] = {
                                'duration_s': duration_s,
                                'start_ts': start_ts
                            }
                    except (ValueError, IndexError):
                        continue # Skip malformed lines
    except FileNotFoundError:
        print(f"Warning: Profiling log file not found at {log_path}")
    return task_data

def calculate_task_timings(dependencies, task_data, docstrings):
    """
    Calculates start and end times for each task based on dependencies and durations.
    Returns a list of dictionaries, each representing a task with its timing info.
    """
    task_info = {}
    
    # Initialize task_info with all known targets and their durations
    for target, deps_list in dependencies.items():
        task_info[target] = {
            'duration': task_data.get(target, {}).get('duration_s', 0.0),
            'start_ts': task_data.get(target, {}).get('start_ts'),
            'docstring': docstrings.get(target, ''),
            'prerequisites': deps_list[0] + deps_list[1],
            'earliest_start': 0.0,
            'earliest_finish': 0.0,
            'latest_start': float('inf'),
            'latest_finish': float('inf'),
            'is_critical': False
        }
    
    # Add any tasks from task_data that are not in dependencies
    for target, data in task_data.items():
        if target not in task_info:
            task_info[target] = {
                'duration': data.get('duration_s', 0.0),
                'start_ts': data.get('start_ts'),
                'docstring': docstrings.get(target, ''),
                'prerequisites': [],
                'earliest_start': 0.0,
                'earliest_finish': 0.0,
                'latest_start': float('inf'),
                'latest_finish': float('inf'),
                'is_critical': False
            }

    # --- Forward Pass (Calculate Earliest Start and Finish Times) ---
    # Create a graph for topological sort
    graph = collections.defaultdict(list)
    in_degree = {task: 0 for task in task_info}
    
    for task_name, info in task_info.items():
        for prereq in info['prerequisites']:
            if prereq in task_info:
                graph[prereq].append(task_name)
                in_degree[task_name] += 1
    
    
    queue = collections.deque([task for task, degree in in_degree.items() if degree == 0])
    
    
    
    
    
    processed_tasks_order = []
    while queue:
        u = queue.popleft()
        processed_tasks_order.append(u)

        # Calculate earliest start and finish for u
        # If u has no prerequisites, earliest_start is 0.0
        # Otherwise, it's the max earliest_finish of its prerequisites.
        max_prereq_ef = 0.0
        for prereq in task_info[u]['prerequisites']:
            if prereq in task_info:
                max_prereq_ef = max(max_prereq_ef, task_info[prereq]['earliest_finish'])
        
        task_info[u]['earliest_start'] = max_prereq_ef
        task_info[u]['earliest_finish'] = task_info[u]['earliest_start'] + task_info[u]['duration']

        for v in graph[u]:
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.append(v)

    # --- Identify reachable tasks from 'all' target ---
    reachable_tasks = set()
    queue_reachable = collections.deque(['all']) # Start from the 'all' target

    while queue_reachable:
        u = queue_reachable.popleft()
        if u in reachable_tasks:
            continue
        reachable_tasks.add(u)
        
        # Add its prerequisites to the queue
        if u in task_info:
            for prereq in task_info[u]['prerequisites']:
                queue_reachable.append(prereq)

    # --- Backward Pass (Calculate Latest Start and Finish Times) ---
    # Project finish time is the max earliest finish of all tasks *reachable* from 'all'
    project_finish_time = max(
        (info['earliest_finish'] for name, info in task_info.items() if name in reachable_tasks),
        default=0
    )

    # Initialize latest_finish for all tasks to project_finish_time
    for task_name, info in task_info.items():
        info['latest_finish'] = project_finish_time
        info['latest_start'] = project_finish_time - info['duration'] # Initial calculation

    # Process tasks in reverse topological order
    for u in reversed(processed_tasks_order):
        # Only calculate for reachable tasks, others will have default latest times
        if u not in reachable_tasks:
            continue

        # If u has successors, its latest_finish is the min latest_start of its successors
        # Otherwise, it's the project_finish_time (already set)
        
        min_successor_ls = float('inf')
        has_successor = False
        for v in graph[u]: # v is a successor of u
            if v in reachable_tasks: # Only consider successors that are also reachable
                min_successor_ls = min(min_successor_ls, task_info[v]['latest_start'])
                has_successor = True
        
        if has_successor:
            task_info[u]['latest_finish'] = min_successor_ls
            task_info[u]['latest_start'] = task_info[u]['latest_finish'] - task_info[u]['duration']
        
        # Determine if task is critical
        task_info[u]['is_critical'] = (abs(task_info[u]['earliest_start'] - task_info[u]['latest_start']) < 1e-9) # Using a small epsilon for float comparison
    
    hanging_tasks = []
    for task_name, info in task_info.items():
        if task_name not in reachable_tasks:
            hanging_tasks.append({
                'name': task_name,
                'duration_s': info['duration'],
                'start_ts': info.get('start_ts'),
                'docstring': info.get('docstring', '')
            })

    gantt_data = []
    for task_name, info in task_info.items():
        # Only include tasks that actually ran (duration > 0) or are significant
        #if (task_name in reachable_tasks) and (info['duration'] > 0 or info['prerequisites'] ): #or info['is_critical'] 
        if (task_name in reachable_tasks) and (info['duration'] > 0 or info['is_critical'] ):  
            gantt_data.append({
                'name': task_name,
                'start_s': info['earliest_start'], # Use earliest start for Gantt chart
                'end_s': info['earliest_finish'],
                'duration_s': info['duration'],
                'is_critical': info['is_critical']
            })
    
    # The data is already sorted topologically, no need for further sorting by start_s
    # gantt_data.sort(key=lambda x: x['start_s'])
    
    return gantt_data, task_info, hanging_tasks

from heapq import heappush, heappop

def sort_gantt_data_topologically(gantt_data: List[Dict[str, Any]], task_info: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Sorts gantt_data topologically, prioritizing tasks with earlier end times
    when topological criteria are equal.
    """
    # Build graph and in-degrees
    graph = collections.defaultdict(list) # graph[prereq] = [task_that_depends_on_prereq]
    in_degree = collections.defaultdict(int)
    
    # Initialize in_degree for all tasks in gantt_data
    for task in gantt_data:
        in_degree[task['name']] = 0

    # Populate graph and in_degree based on task_info (which has prerequisites)
    for task_name, info in task_info.items():
        for prereq in info['prerequisites']:
            if prereq in in_degree and task_name in in_degree: # Ensure both exist in the current gantt_data set
                graph[prereq].append(task_name)
                in_degree[task_name] += 1

    # Priority queue: (end_time, task_name)
    # We use negative end_time to simulate max-heap for end_time,
    # but since we want earlier end times first, we use positive end_time.
    # The example used (end, id) for min-heap, which means earlier end times first.
    heap = []
    task_map = {task['name']: task for task in gantt_data} # Map for quick lookup

    for task_name, degree in in_degree.items():
        if degree == 0:
            task = task_map[task_name]
            heappush(heap, (task['end_s'], task['name']))

    sorted_result = []
    while heap:
        end_time, task_name = heappop(heap)
        task = task_map[task_name]
        sorted_result.append(task)
        
        # Update dependencies for neighbors
        for neighbor_name in graph[task_name]:
            in_degree[neighbor_name] -= 1
            if in_degree[neighbor_name] == 0:
                neighbor_task = task_map[neighbor_name]
                heappush(heap, (neighbor_task['end_s'], neighbor_name))

    # Check for cycles (if any task still has in_degree > 0)
    if len(sorted_result) != len(gantt_data):
        # This indicates a cycle or some tasks were not reachable from initial queue
        # For now, we'll just return the partial result, but a real implementation
        # might raise an error or handle it differently.
        print("Warning: Cycle detected or some tasks not processed in topological sort.")
        # Fallback to sorting by start_s if topological sort fails to process all
        gantt_data.sort(key=lambda x: (x['start_s'], x['end_s']))
        return gantt_data
    
    return sorted_result

def format_time(seconds):
    t=int(seconds)
    hours = t // 3600
    minutes = (t % 3600) // 60
    seconds = t % 60
    
    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    elif minutes > 0:
        return f"{minutes:02d}:{seconds:02d}"
    else:
        return f"{seconds:02d}"

def remove_data_prefix(path):
    if path.startswith("data/"):
        return path[5:]
    return path    
    
    
def generate_gantt_html(gantt_data, output_path, hanging_tasks, task_info):
    """
    Generates an HTML file with a simple Gantt chart using HTML/CSS.
    """
    if not gantt_data:
        html_content = "<html><body><h1>No Gantt data to display.</h1></body></html>"
        with open(output_path, 'w') as f:
            f.write(html_content)
        return

    # Find the total duration to scale the chart
    max_end_time = max(task['end_s'] for task in gantt_data) if gantt_data else 0
    min_start_time = min(task['start_s'] for task in gantt_data) if gantt_data else 0
    total_chart_duration = max_end_time - min_start_time

    total_tasks_duration   = 0.0
    critical_path_duration = 0.0
    for task in gantt_data:
        total_tasks_duration += task['duration_s']
        if task['is_critical']:
            critical_path_duration += task['duration_s']
    
    tasks_html = []
    # Assign a row index to each task for vertical positioning
    task_row_map = {task['name']: i for i, task in enumerate(gantt_data)}

    for i, task in enumerate(gantt_data):
        # Calculate position and width in percentages
        start_percent = ((task['start_s'] - min_start_time) / total_chart_duration) * 100 if total_chart_duration > 0 else 0
        duration_percent = (task['duration_s'] / total_chart_duration) * 100 if total_chart_duration > 0 else 0
        
        # Ensure minimum width for visibility of very short tasks
        if duration_percent > 0 and duration_percent < 0.1:
            duration_percent = 0.1

        # Vertical position based on index
        top_offset = i * 30 # 30px per row

        task_name = task['name']
        prereqs = task_info.get(task_name, {}).get('prerequisites', [])
        display_prereqs = [remove_data_prefix(p) for p in prereqs]
        
        tooltip_text = "Prerequisites:\n" + "\n".join(display_prereqs) if display_prereqs else "No direct prerequisites"
        tooltip_text_escaped = html.escape(tooltip_text, quote=True)

        tasks_html.append(f"""
            <div class="gantt-task {'critical-task' if task['is_critical'] else ''}" style="left: {start_percent}%; width: {duration_percent}%; top: {top_offset}px;" title="{tooltip_text_escaped}">
                <!-- <span class="task-name">{task['name']}</span> -->
                <span class="task-duration">{format_time(task['duration_s'])}</span>
            </div>
        """)

    hanging_tasks_html = ""
    if hanging_tasks:
        hanging_tasks_rows_html = []
        # Sort hanging tasks by name for consistent ordering
        hanging_tasks.sort(key=lambda x: x['name'])
        for task in hanging_tasks:
            last_run_str = (
                datetime.fromtimestamp(task['start_ts']).strftime('%Y-%m-%d %H:%M:%S')
                if task['start_ts'] else 'N/A'
            )
            docstring_str = task['docstring'] or ''
            
            hanging_tasks_rows_html.append(
                f"<tr>"
                f"<td><strong>{remove_data_prefix(task['name'])}</strong></td>"
                f"<td>{format_time(task['duration_s'])}</td>"
                f"<td>{last_run_str}</td>"
                f"<td>{docstring_str}</td>"
                f"</tr>"
            )

        hanging_tasks_html = f"""
        <div class="hanging-tasks-section">
            <h2>Hanging Tasks (not reachable from 'all')</h2>
            <table class="hanging-tasks-table">
                <thead>
                    <tr>
                        <th>Task</th>
                        <th>Duration</th>
                        <th>Last Run</th>
                        <th>Description</th>
                    </tr>
                </thead>
                <tbody>
                    {''.join(hanging_tasks_rows_html)}
                </tbody>
            </table>
        </div>
        """

    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Makefile Gantt Chart</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f4f4f4;
        }}
        h1 {{
            color: #333;
        }}
        .gantt-chart-container {{
            display: flex;
            border: 1px solid #ccc;
            background-color: #fff;
            padding: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            min-height: {len(gantt_data) * 30 + 20}px; /* Total height based on tasks + padding */
        }}
        .gantt-labels {{
            flex: 0 0 350px; /* Do not grow or shrink, fixed width */
            padding-right: 10px;
            box-sizing: border-box;
        }}
        .gantt-label-item {{
            display: flex;
            justify-content: space-between; /* Distribute name and duration */
            align-items: center;
            height: 30px;
            line-height: 30px;
            font-size: 12px;
            color: #555;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            text-align: right;
        }}
        .gantt-label-name {{
            flex-grow: 1;
            text-align: right;
            padding-right: 5px;
        }}
        .gantt-label-duration {{
            width: 60px; /* Fixed width for duration */
            text-align: right;
            font-size: 10px;
            color: #777;
        }}
        .gantt-label-item.critical-task-label .gantt-label-name,
        .gantt-label-item.critical-task-label .gantt-label-duration {{
            font-weight: bold;
            color: #D32F2F; /* Darker red for critical path labels */
        }}
        .gantt-timeline {{
            flex-grow: 1;
            position: relative;
            min-height: {len(gantt_data) * 30}px; /* Total height based on tasks */
			margin-right: 20px;
        }}
        .gantt-task {{
            position: absolute;
            height: 20px; /* Height of each task bar */
            background-color: #4CAF50;
            color: white;
            text-align: center;
            line-height: 20px;
            border-radius: 3px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            box-sizing: border-box;
            /*padding: 0 5px;*/
            margin-top: 5px; /* Center vertically within 30px row */
            min-width: 1px; /* Ensure visibility for very short tasks */
        }}
        .gantt-task.critical-task {{
            background-color: #F44336; /* Red for critical path tasks */
            font-weight: bold;
        }}
        .task-name {{
            font-size: 12px;
            font-weight: bold;
        }}
        .task-duration {{
            font-size: 10px;
            margin-left: 5px;
        }}
        .summary-statistics, .hanging-tasks-section {{
            margin-top: 20px;
            padding: 15px;
            border: 1px solid #ccc;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }}
        .summary-statistics h2, .hanging-tasks-section h2 {{
            margin-top: 0;
            color: #333;
        }}
        .summary-statistics p, .hanging-tasks-section ul {{
            margin-bottom: 5px;
        }}
        .hanging-tasks-section ul {{
            list-style-type: none;
            padding-left: 0;
        }}
        .hanging-tasks-section li {{
            margin-bottom: 3px;
            color: #555;
        }}
        .hanging-tasks-table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }}
        .hanging-tasks-table th, .hanging-tasks-table td {{
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
            font-size: 12px;
        }}
        .hanging-tasks-table th {{
            background-color: #f2f2f2;
            font-weight: bold;
        }}
        .hanging-tasks-table tr:nth-child(even) {{
            background-color: #f9f9f9;
        }}
        .hanging-tasks-table tr:hover {{
            background-color: #f1f1f1;
        }}
    </style>
</head>
<body>
    <h1>Makefile Build Gantt Chart</h1>
    <div class="gantt-chart-container">
        <div class="gantt-labels">
            {''.join([f'''
            <div class="gantt-label-item {"critical-task-label" if task["is_critical"] else ""}">
                <span class="gantt-label-name">{remove_data_prefix(task["name"])}</span>
                <span class="gantt-label-duration">{format_time(task["duration_s"])}</span>
            </div>''' for task in gantt_data])}
        </div>
        <div class="gantt-timeline">
            {''.join(tasks_html)}
        </div>
    </div>

    <div class="summary-statistics">
        <h2>Summary Statistics</h2>
        <p><strong>Total duration of all tasks:</strong> {format_time(total_tasks_duration)}</p>
        <p><strong>Critical path duration:</strong> {format_time(critical_path_duration)}</p>
    </div>
    {hanging_tasks_html}

</body>
</html>
"""
	
    with open(output_path, 'w') as f:
        f.write(html_content)
    print(f"Gantt chart generated at {output_path}")

if __name__ == "__main__":
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    MAKEFILE_PATH = os.path.join(PROJECT_ROOT, 'makefile')
    PROFILING_LOG_PATH = os.path.join(PROJECT_ROOT, 'makefile-profiling.log')
    OUTPUT_HTML_PATH = os.path.join(PROJECT_ROOT, 'data', 'export', 'gantt_chart.html')

    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_HTML_PATH), exist_ok=True)

    # Read makefile content
    with open(MAKEFILE_PATH, 'r') as f:
        makefile_content = f.read()

    # Parse makefile
    ast = parse_makefile_content(makefile_content)
    dependencies, _, _, _ = get_dependencies_influences(ast)
    print(f"Parsed {len(dependencies)} targets from makefile.")

    # Create a docstring map
    docstrings = {
        item['target']: item['docs']
        for _, item in ast
        if _ == Tokens.target and item.get('docs')
    }

    # Parse profiling log
    task_data = parse_profiling_log(PROFILING_LOG_PATH)
    print(f"Parsed {len(task_data)} task records from profiling log.")

    # Calculate task timings
    gantt_data, task_info, hanging_tasks = calculate_task_timings(dependencies, task_data, docstrings)
    print(f"Calculated timings for {len(gantt_data)} tasks.")

    # Sort gantt_data topologically with end_s as secondary criterion
    gantt_data = sort_gantt_data_topologically(gantt_data, task_info)

    # Generate HTML
    generate_gantt_html(gantt_data, OUTPUT_HTML_PATH, hanging_tasks, task_info)
