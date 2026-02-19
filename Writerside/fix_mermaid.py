#!/usr/bin/env python3
import re
import glob
import os

def fix_mermaid_diagrams(content):
    """Convert Markdown mermaid blocks to Writerside format"""
    # Pattern to match <!--```mermaid ... ```-->
    pattern = r'<!--```mermaid\n(.*?)\n```-->'

    def replace_block(match):
        mermaid_code = match.group(1)
        return f'<code-block lang="mermaid">\n{mermaid_code}\n</code-block>'

    # Replace all mermaid blocks
    content = re.sub(pattern, replace_block, content, flags=re.DOTALL)

    return content

# Change to topics directory
os.chdir('topics')

# Process all presupuesto-*.md files
for filename in glob.glob('presupuesto-*.md'):
    print(f'Processing {filename}...')

    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix mermaid diagrams
    new_content = fix_mermaid_diagrams(content)

    # Write back
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f'✓ Fixed {filename}')

print('Done!')
