#!/bin/sh
S=/storage/emulated/0/ฝากงาน/index.html
fail=0
if grep -q 'collectionGroup' "$S"; then echo "FAIL collectionGroup still used"; fail=1; else echo "PASS collectionGroup removed"; fi
check() { if grep -q "$1" "$S"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'const messageListeners = {}'
check 'messageListeners\[id\]'
check 'messageListeners = {}' 
exit $fail
