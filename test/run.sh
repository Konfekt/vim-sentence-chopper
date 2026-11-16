#!/bin/sh
# Run the tests in each available editor: test/run.sh [vim|nvim ...]
cd "$(dirname "$0")/.." || exit 1
[ $# -eq 0 ] && set -- vim nvim
status=0
for editor in "$@"; do
  command -v "$editor" >/dev/null || { echo "skip $editor (not found)"; continue; }
  rm -f test/results.txt
  case $editor in
    *nvim*) "$editor" --headless -u NONE -i NONE -S test/test.vim ;;
    *) "$editor" -Nu NONE -i NONE -es -S test/test.vim ;;
  esac
  rc=$?
  echo "== $editor"
  cat test/results.txt 2>/dev/null || echo "no results"
  [ $rc -eq 0 ] || status=1
done
exit $status
