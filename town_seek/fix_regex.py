content = open('lib/services/smart_route_service.dart', 'r', encoding='utf-8').read()

# The broken line to find and replace
old = ".replaceAll(RegExp(r'[\\[\\]{}\"\\'\\\\]'), '')"
new_lines = ".replaceAll('[', '').replaceAll(']', '').replaceAll('{', '').replaceAll('}', '').replaceAll('\"', '').replaceAll(\"'\", '')"

# Since the exact string might differ, search more broadly
import re
# Find and fix the specific problematic replaceAll line
# The pattern is: .replaceAll(RegExp(r'[...]'), '')
fixed = re.sub(r"\.replaceAll\(RegExp\(r'[^']+'\),\s*''\)", new_lines, content)

if fixed != content:
    open('lib/services/smart_route_service.dart', 'w', encoding='utf-8').write(fixed)
    print("Fixed!")
else:
    print("Pattern not found — checking lines around 112:")
    lines = content.split('\n')
    for i, line in enumerate(lines[108:118], start=109):
        print(f"{i}: {repr(line)}")
