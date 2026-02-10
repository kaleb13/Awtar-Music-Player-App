import os
import re
from collections import defaultdict

keys = defaultdict(list)
pattern = re.compile(r"ValueKey\((['\"].*?['\"])\)")

for root, dirs, files in os.walk('.'):
    if '.git' in dirs: dirs.remove('.git')
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for match in pattern.finditer(content):
                        keys[match.group(1)].append(path)
            except:
                pass

for key, paths in keys.items():
    if len(paths) > 1:
        print(f"Duplicate Key: {key} found in: {paths}")
