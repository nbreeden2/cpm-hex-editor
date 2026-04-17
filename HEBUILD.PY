"""HEBUILD.PY - Patch COLOR EQU value in HECONFIG.INC for variant builds.

Usage: python HEBUILD.PY <color>
  color  - 0 or 1 (COLOR EQU value in HECONFIG.INC)
"""

import re
import sys

def patch_equ(filepath, name, value):
    """Replace 'name EQU <old>' with 'name EQU <new>' preserving comment."""
    with open(filepath, 'r') as f:
        text = f.read()
    pattern = re.compile(
        r'^(' + re.escape(name) + r'\s+EQU\s+)\d+(\s*;.*)?$',
        re.MULTILINE
    )
    new_text, count = pattern.subn(
        lambda m: m.group(1) + str(value) + (m.group(2) or ''),
        text
    )
    if count == 0:
        print(f'WARNING: {name} EQU not found in {filepath}')
        return False
    with open(filepath, 'w') as f:
        f.write(new_text)
    return True

def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    color = int(sys.argv[1])

    if color not in (0, 1):
        print(f'ERROR: color must be 0 or 1, got {color}')
        sys.exit(1)

    ok = patch_equ('HECONFIG.INC', 'COLOR', color)

    label = 'color' if color else 'mono'
    print(f'Patched: {label}')

    if not ok:
        sys.exit(1)

if __name__ == '__main__':
    main()
