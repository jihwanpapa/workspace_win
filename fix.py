import os
path = os.path.expanduser('~/DEV/sshw/sshw.sh')
with open(path, 'r') as f:
    content = f.read()
content = content.replace('-re {[$#>%\]] ?} {', '-re {[]$#>%] ?} {')
with open(path, 'w') as f:
    f.write(content)
print("File updated successfully.")
