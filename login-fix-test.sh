#!/bin/sh
R=/storage/emulated/0/fakjob-pages/firestore.rules
S=/storage/emulated/0/ฝากงาน/index.html
fail=0
check() { if grep -q "$1" "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'allow read: if request.auth != null && resource.data.uid == request.auth.uid;' "$R"
check 'allow update: if request.auth != null && resource.data.uid == request.auth.uid && request.resource.data.uid == request.auth.uid;' "$R"
check 'permission-denied' "$S"
exit $fail
