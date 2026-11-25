#!/bin/sh
S=/storage/emulated/0/ฝากงาน/index.html
fail=0
check() { if grep -q "$1" "$S"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'let own = {};'
check 'likedIds: state.likedIds'
check 'own.uid || authUser.uid'
exit $fail
