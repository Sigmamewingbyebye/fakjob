#!/bin/sh
SRC=/storage/emulated/0/ฝากงาน/index.html
fail=0
check() { if grep -q "$1" "$SRC"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'function localDateStr'
check 'const todayStr = localDateStr();'
check 'saveLocal();' "$SRC"
check 'invalid-credential'
check 'updateStatCounts'
check '700 \* 1024'
if grep -q 'if (wanted) fetchProfileRow' "$SRC"; then echo "FAIL dead fetchProfileRow call"; fail=1; else echo "PASS dead fetchProfileRow removed"; fi
exit $fail
