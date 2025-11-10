import collections
import re
import os
import tempfile
from datetime import datetime, timedelta
from typing import Any, Dict, Generator, List, Tuple, TextIO, Pattern
from enum import Enum # Import Enum
from more_itertools import peekable

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
        match = re.match(
            r'(.+?):\s*(?:([^|#]+?)\s*)?(?:\|\s*([^#]+?)\s*)?\s*(?:##(.+))?$',
            line
        )
        if not match:
            # Fallback for targets without explicit dependencies or docstrings
            match = re.match(r'(.+?):', line)
            if not match:
                return # Skip if not a valid target line

        target_name = match.group(1).strip()
        deps_str = match.group(2) if match.group(2) else ''
        order_deps_str = match.group(3) if match.group(3) else ''
        docstring = match.group(4) if match.group(4) else ''

        deps = [p.strip() for p in deps_str.split()] if deps_str else []
        order_deps = [p.strip() for p in order_deps_str.split()] if order_deps_str else []

        body = parse_body()
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
    Parses the makefile-profiling.log to extract task durations.
    Returns a dictionary where keys are target names and values are durations in seconds.
    If a target appears multiple times, the last duration is used.
    """
    durations = {}
    with open(log_path, 'r') as f:
        for line in f:
            parts = line.split()
            # Expected format: START_TIMESTAMP-PID-SOME_ID END_TIMESTAMP DURATION STATUS TARGET_NAME [DESCRIPTION]
            if len(parts) >= 5:
                try:
                    duration_s = int(parts[2])
                    target_name = parts[4]
                    durations[target_name] = duration_s
                except ValueError:
                    continue # Skip lines where duration is not an integer
    return durations

def calculate_task_timings(dependencies, durations):
    """
    Calculates start and end times for each task based on dependencies and durations.
    Returns a list of dictionaries, each representing a task with its timing info.
    """
    task_info = {}
    
    # Initialize task_info with all known targets and their durations
    for target, deps_list in dependencies.items():
        task_info[target] = {
            'duration': durations.get(target, 0.0),
            'prerequisites': deps_list[0] + deps_list[1],
            'earliest_start': 0.0,
            'earliest_finish': 0.0,
            'latest_start': float('inf'),
            'latest_finish': float('inf'),
            'is_critical': False
        }
    
    # Add any tasks from durations that are not in dependencies (e.g., phony targets not explicitly listed)
    for target, duration in durations.items():
        if target not in task_info:
            task_info[target] = {
                'duration': duration,
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

    # --- Backward Pass (Calculate Latest Start and Finish Times) ---
    project_finish_time = max(info['earliest_finish'] for info in task_info.values())

    # Initialize latest_finish for all tasks to project_finish_time
    for task_name, info in task_info.items():
        info['latest_finish'] = project_finish_time
        info['latest_start'] = project_finish_time - info['duration'] # Initial calculation

    # Process tasks in reverse topological order
    for u in reversed(processed_tasks_order):
        # If u has successors, its latest_finish is the min latest_start of its successors
        # Otherwise, it's the project_finish_time (already set)
        
        min_successor_ls = float('inf')
        has_successor = False
        for v in graph[u]: # v is a successor of u
            min_successor_ls = min(min_successor_ls, task_info[v]['latest_start'])
            has_successor = True
        
        if has_successor:
            task_info[u]['latest_finish'] = min_successor_ls
            task_info[u]['latest_start'] = task_info[u]['latest_finish'] - task_info[u]['duration']
        
        # Determine if task is critical
        task_info[u]['is_critical'] = (abs(task_info[u]['earliest_start'] - task_info[u]['latest_start']) < 1e-9) # Using a small epsilon for float comparison

    gantt_data = []
    for task_name, info in task_info.items():
        # Only include tasks that actually ran (duration > 0) or are significant
        if info['duration'] > 0 or info['prerequisites']:
            gantt_data.append({
                'name': task_name,
                'start_s': info['earliest_start'], # Use earliest start for Gantt chart
                'end_s': info['earliest_finish'],
                'duration_s': info['duration'],
                'is_critical': info['is_critical']
            })
    
    # Sort by start time for better visualization
    gantt_data.sort(key=lambda x: x['start_s'])
    
    return gantt_data

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
    
    
def generate_gantt_html(gantt_data, output_path):
    """
    Generates an HTML file with a simple Gantt chart using HTML/CSS.
    """
    if not gantt_data:
        html_content = "<html><body><h1>No Gantt data to display.</h1></body></html>"
        with open(output_path, 'w') as f:
            f.write(html_content)
        return

    # Find the total duration to scale the chart
    max_end_time = max(task['end_s'] for task in gantt_data)
    min_start_time = min(task['start_s'] for task in gantt_data)
    total_chart_duration = max_end_time - min_start_time
    
    # Scale factor for width (e.g., 100px per second, adjust as needed)
    chart_width_px = 1000 # Max chart width in pixels
    scale_factor =0.75* chart_width_px / total_chart_duration if total_chart_duration > 0 else 0

    tasks_html = []
    # Assign a row index to each task for vertical positioning
    # A simple approach: just assign them sequentially
    task_row_map = {task['name']: i for i, task in enumerate(gantt_data)}

    for i, task in enumerate(gantt_data):
        # Calculate position and width
        start_offset = (task['start_s'] - min_start_time) * scale_factor
        duration_width = task['duration_s'] * scale_factor
        
        # Ensure minimum width for visibility
        if duration_width < 1: duration_width = 1 

        # Vertical position based on index
        top_offset = i * 30 # 30px per row

        tasks_html.append(f"""
            <div class=\"gantt-task {'critical-task' if task['is_critical'] else ''}\" style=\"left: {start_offset}px; width: {duration_width}px; top: {top_offset}px;\">
                <!-- <span class=\"task-name\">{task['name']}</span> -->
                <span class=\"task-duration\">{format_time(task['duration_s'])}</span>
            </div>
        """)

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
            position: relative;
            width: 100%;
            max-width: {chart_width_px + 350}px; /* Adjust based on chart_width_px + labels */
            border: 1px solid #ccc;
            background-color: #fff;
            padding: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            overflow-x: auto;
            min-height: {len(gantt_data) * 30 + 20}px; /* Total height based on tasks + padding */
        }}
        .gantt-labels {{
            float: left;
            width: 280px; /* Width for task names on the left */
            padding-right: 10px;
            box-sizing: border-box;
        }}
        .gantt-label-item {{
            height: 30px;
            line-height: 30px;
            font-size: 12px;
            color: #555;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            text-align: right;
        }}
        .gantt-label-item.critical-task-label {{
            font-weight: bold;
            color: #D32F2F; /* Darker red for critical path labels */
        }}
        .gantt-timeline {{
            margin-left: 290px; /* Offset for labels + padding */
            position: relative;
            min-height: {len(gantt_data) * 30}px; /* Total height based on tasks */
            width: {chart_width_px}px;
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
            padding: 0 5px;
            margin-top: 5px; /* Center vertically within 30px row */
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
    </style>
</head>
<body>
    <h1>Makefile Build Gantt Chart</h1>
    <div class="gantt-chart-container">
        <div class="gantt-labels">
            {''.join([f'<div class="gantt-label-item {"critical-task-label" if task["is_critical"] else ""}">{remove_data_prefix(task["name"])}</div>' for task in gantt_data])}
        </div>
        <div class="gantt-timeline">
            {''.join(tasks_html)}
        </div>
        <div style="clear:both;"></div>
    </div>
</body>
</html>    """
	
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

    # Parse profiling log
    durations = parse_profiling_log(PROFILING_LOG_PATH)
    print(f"Parsed {len(durations)} task durations from profiling log.")

    # Calculate task timings
    gantt_data = calculate_task_timings(dependencies, durations)
    print(f"Calculated timings for {len(gantt_data)} tasks.")

    # Generate HTML
    generate_gantt_html(gantt_data, OUTPUT_HTML_PATH)
