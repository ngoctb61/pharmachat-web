#!/bin/sh
# PostToolUse (Write|Edit): run prettier on the edited file so `npm run lint`
# (prettier --check) stays clean. Files prettier cannot parse, files listed in
# .prettierignore and files outside this checkout are left alone. Does nothing
# until `npm ci` has installed prettier.
PAYLOAD=$(cat)
. "$(dirname "$0")/lib.sh"

file=$(json_field '.tool_input.file_path' file_path)
[ -n "$file" ] && [ -f "$file" ] || exit 0

root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null) || exit 0
prettier=$root/node_modules/.bin/prettier
[ -x "$prettier" ] || exit 0

cd "$root" || exit 0
"$prettier" --write --ignore-unknown --log-level warn "$file" >&2 || true
exit 0
