#!/bin/sh
S=/storage/emulated/0/ฝากงาน/index.html
fail=0
check() { if grep -q "$1" "$S"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'function restoreProfileFromLegacy'
check 'profilePicCrop:'
check 'restoreProfileFromLegacy(account.username)'
exit $fail
