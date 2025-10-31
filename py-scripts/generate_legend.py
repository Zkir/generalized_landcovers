import re

def parse_mss_styles(style_content, landcover_content):
    styles = {}
    variables = {}

    for line in style_content.split('\n'):
        match = re.match(r'@(\w+):\s*(#[0-9a-fA-F]{3,6});', line)
        if match:
            var_name, color = match.groups()
            variables[f'@{var_name}'] = color

    # Manual, state-machine-like parsing
    in_block = False
    current_features = []
    for line in landcover_content.split('\n'):
        line = line.strip()
        if line.startswith('['):
            # Find all features on this line, e.g., [feature='sand'],[feature='beach']
            features_on_line = re.findall(r"\bfeature=['\"]([^'\"]+)['\"]", line)
            if features_on_line:
                current_features.extend(features_on_line)
            if '{' in line:
                in_block = True
        
        if in_block:
            fill_match = re.search(r'polygon-fill:\s*([^;]+);', line)
            pattern_match = re.search(r'polygon-pattern-file:\s*url\([\'\\]?(.+?)[\'\\]?\)[;]?', line)
            opacity_match = re.search(r'polygon-opacity:\s*([\d\.]+);', line)

            if fill_match:
                color_val = fill_match.group(1).strip()
                color = variables.get(color_val, color_val)
                for feature in current_features:
                    if feature not in styles: styles[feature] = {}
                    styles[feature]['color'] = color

            if pattern_match:
                pattern = pattern_match.group(1)
                for feature in current_features:
                    if feature not in styles: styles[feature] = {}
                    styles[feature]['pattern'] = pattern

            if opacity_match:
                opacity = float(opacity_match.group(1))
                for feature in current_features:
                    if feature not in styles: styles[feature] = {}
                    styles[feature]['opacity'] = opacity

        if '}' in line:
            in_block = False
            current_features = []

    # Post-process to add default opacity and None for pattern
    for feature, data in styles.items():
        if 'opacity' not in data:
            data['opacity'] = 1.0
        if 'pattern' not in data:
            data['pattern'] = None
        if 'color' in data and len(data['color']) == 4 and data['color'].startswith('#'):
             c = data['color']
             data['color'] = f'#{c[1]}{c[1]}{c[2]}{c[2]}{c[3]}{c[3]}'

    return styles

def generate_legend_html(styles):
    html = '<div class="legend-container">'
    html += '<h5>Map Legend <span class="toggle-legend">[hide]</span></h5>'
    html += '<div class="legend-items">'

    sorted_features = sorted(styles.keys())

    for feature in sorted_features:
        style = styles.get(feature)
        if not style or 'color' not in style:
            continue

        color = style['color']
        pattern = style['pattern']
        opacity = style['opacity']

        background_style = f'background-color: {color};'
        if pattern:
            web_pattern_path = pattern.replace(r'\\', '/')
            background_style += f' background-image: url(../{web_pattern_path}); background-repeat: repeat;'
        
        item_html = f'''
        <div class="legend-item">
            <span class="legend-swatch" style="{background_style} opacity: {opacity};"></span>
            <span class="legend-label">{feature.replace('_', ' ')}</span>
        </div>'''
        html += item_html

    html += '</div></div>'
    return html

if __name__ == '__main__':
    try:
        with open('style.mss', 'r', encoding='utf-8') as f:
            style_content = f.read()
    except FileNotFoundError:
        style_content = ''

    try:
        with open('landcovers.mss', 'r', encoding='utf-8') as f:
            landcover_content = f.read()
    except FileNotFoundError:
        print("Error: landcovers.mss not found.")
        exit(1)

    parsed_styles = parse_mss_styles(style_content, landcover_content)
    legend_html = generate_legend_html(parsed_styles)
    print(legend_html)