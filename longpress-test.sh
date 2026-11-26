#!/bin/sh
S=/sdcard/MargyCode/fakjob-pages/index.html
fail=0
check() { if grep -q "$1" "$S"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
check 'let activeReactionMsgId = null'
check 'pointerdown'
check 'pointerup'
check 'longPressTimer'
check 'chat-reactions.is-open'
check 'closeReactionPicker'
exit $fail
