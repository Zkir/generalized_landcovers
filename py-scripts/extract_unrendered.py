#!/usr/bin/env python
# =================================================================
# This script extracts unrendered landcover tags from taginfo.json
# and then uses osmium-tool to filter a planet.osm.pbf file
# to create an osm file with only those unrendered landcovers.
# =================================================================

import json
import os
import subprocess

def extract_unrendered_tags(json_file):
    """
    Parses the taginfo.json file to extract the unrendered tags.
    """
    with open(json_file, 'r', encoding='utf-8') as f:
        taginfo_data = json.load(f)

    unrendered_tags = []
    for tag in taginfo_data.get('tags', []):
        if tag.get('description') == 'Accepted as landcover, but not rendered.':
            key = tag.get('key')
            value = tag.get('value')
            if key and value:
                unrendered_tags.append(f"{key}={value}")
    
    return unrendered_tags

def main():
    """
    Main function to extract tags and run osmium.
    """
    json_file = 'taginfo.json'
    planet_file = 'data/source/planet-latest-updated.osm.pbf'
    output_file = 'data/export/unrendered_landcovers.osm'

    if not os.path.exists(json_file):
        print(f"Error: {json_file} not found. Please generate it first.")
        exit(1)

    if not os.path.exists(planet_file):
        print(f"Error: {planet_file} not found. Please download it first.")
        exit(1)

    unrendered_tags = extract_unrendered_tags(json_file)

    if not unrendered_tags:
        print("No unrendered tags found.")
        return

    # Construct the osmium command
    osmium_command = ['osmium', 'tags-filter', planet_file]
    
    # Add tags to the command, prefixed with 'a/' for areas
    for tag in unrendered_tags:
        # osmium can't handle tags with spaces unless they are quoted.
        # The tag "natural=wetland;wood" contains a semicolon, which should be fine.
        osmium_command.append(f'a/{tag}')

    osmium_command.extend(['-o', output_file])
    osmium_command.extend(['--overwrite'])

    print("Running osmium command:")
    print(' '.join(osmium_command))

    # Execute the command
    try:
        subprocess.run(osmium_command, check=True)
        print(f"Successfully created {output_file}")
    except subprocess.CalledProcessError as e:
        print(f"Error running osmium: {e}")
        exit(1)
    except FileNotFoundError:
        print("Error: 'osmium' command not found. Please make sure osmium-tool is installed and in your PATH.")
        exit(1)

if __name__ == '__main__':
    main()