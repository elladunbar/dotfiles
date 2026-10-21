# Shell tools (macOS + nix)
- `sed` is GNU sed: use `sed -i 's/a/b/' f`, never `sed -i '' ...`.
- Other CLI tools are the macOS/BSD versions (`date`, `stat`, `xargs`, `awk`, `tar`, `cut`, `head`, `readlink`, ...): use BSD flags, e.g. `date -v`, `stat -f`. There's no `timeout`.
