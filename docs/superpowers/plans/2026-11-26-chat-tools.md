# Chat Tools and Desktop Nav Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add hide-chat, reply, reactions, a hover-revealed desktop bottom bar, and merge duplicate direct chats.

**Architecture:** All chat features are fields on existing Firestore docs: `hiddenChatIds` on the account doc, `replyTo` and `reactions` on message docs. The UI renders them inside existing chat render functions. Desktop nav is CSS-only plus the existing `mousemove` listener. Duplicate direct chats are merged at `startDirectChat` time.

**Tech Stack:** Single-file HTML/CSS/vanilla JS, Firebase Auth + Firestore compat SDK v10.12.2, GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-11-26-chat-tools-design.md`

## Global Constraints

- Source: `/storage/emulated/0/ฝากงาน/index.html`; deploy copy: `/storage/emulated/0/fakjob-pages/index.html`; commit and push to `main`.
- No Firestore rules changes and no re-publishing.
- No new Firestore collections; only fields on existing docs.
- Emoji set exactly `❤️ 👍 😂 😮 😢`; one reaction per uid per emoji; re-tap removes.
- Reply preview: sender name + first 80 characters.
- Desktop reveal radius: ~120px from the bottom edge; persistent decorative hint strip.
- Tests are repeatable grep/shell assertions (no JS test runner available).

## Review Focus

1. Hidden chat must not appear for other accounts (it is per-account data, not a deleted doc) — Task 1.
2. Reply to a legacy message without `replyTo` must not break rendering — Task 2.
3. Reaction toggling must not duplicate a uid in the array — Task 3.
4. Duplicate direct chats for the same pair must collapse to one, with extras' messages deleted — Task 4.
5. Desktop nav must remain usable on touch devices (mobile keeps the always-visible bar) — Task 5.

---

### Task 1: Hide a chat for the current account

**Files:**
- Modify: `ฝากงาน/index.html` (state, `saveLocal`, `loadState`, `renderChatHtml`, `bindChat`, `hydrateChats`, `applyRemoteChats`)

**Interfaces:**
- Consumes: `state.account`, `me()`, `db`, `authUser`.
- Produces: `state.hiddenChatIds`, `isChatHidden(id)`, `toggleHideChat(id)`.

- [ ] **Step 1: Write the failing test** — `task1-test.sh` asserts `hiddenChatIds`, `function isChatHidden`, `data-chat-hide`.
- [ ] **Step 2: Run it; expected FAIL** on all three.
- [ ] **Step 3: Implement state + persistence** — add `hiddenChatIds: []` to `state`; include it in `saveLocal`, `loadState`, `saveState`, and the `accounts/{username}` write in `cloudPush`; define `isChatHidden(id)` and `toggleHideChat(id)` (writes the account doc via `update({hiddenChatIds})`).
- [ ] **Step 4: Filter rendering** — `renderChatHtml` excludes hidden chats from `myChats`/`publicGroups`; add a `data-chat-hide` button on each chat row and bind it in `bindChat` with a confirm.
- [ ] **Step 5: Run test; expected PASS; commit** `feat: hide chats per account`.

### Task 2: Reply to a message

**Files:**
- Modify: `ฝากงาน/index.html` (`renderMessagesHtml`, `bindChatRoom`, `sendChatMessage`)

**Interfaces:**
- Consumes: `currentChat()`, `me()`, `state.account`.
- Produces: `replyTarget` global, `clearReply()`, `sendChatMessage` writes `replyTo`.

- [ ] **Step 1: Write the failing test** — `task2-test.sh` asserts `replyTarget`, `replyTo:`, `data-reply`.
- [ ] **Step 2: Run it; expected FAIL.**
- [ ] **Step 3: Implement** — add `let replyTarget = null;`; render a `data-reply` button per message; clicking sets `replyTarget` to `{id, sender, text.slice(0,80)}` and focuses the composer; show a small "ตอบกลับ … ×" chip above the composer with `clearReply()`.
- [ ] **Step 4: Render and send** — `renderMessagesHtml` shows a quoted line when `m.replyTo` exists; `sendChatMessage` includes `replyTo: replyTarget || undefined`, then `clearReply()`.
- [ ] **Step 5: Run test; expected PASS; commit** `feat: reply to chat messages`.

### Task 3: Emoji reactions

**Files:**
- Modify: `ฝากงาน/index.html` (CSS near `.chat-bubble`, `renderMessagesHtml`, `bindChatRoom`)

**Interfaces:**
- Consumes: `authUser.uid`, `db` (message docs at `chats/{chatId}/messages/{msgId}`).
- Produces: `REACTIONS`, `toggleReaction(chatId, msgId, emoji)`.

- [ ] **Step 1: Write the failing test** — `task3-test.sh` asserts `REACTIONS`, `toggleReaction`, `data-react`.
- [ ] **Step 2: Run it; expected FAIL.**
- [ ] **Step 3: Implement** — `const REACTIONS = ['❤️','👍','😂','😮','😢'];` render a `data-react` button under each bubble and count badges from `m.reactions`.
- [ ] **Step 4: Toggle** — `toggleReaction` reads `m.reactions || {}`, toggles `authUser.uid` in the emoji array, then `db.collection('chats').doc(chatId).collection('messages').doc(msgId).update({reactions: next})`; re-render on success.
- [ ] **Step 5: Run test; expected PASS; commit** `feat: emoji reactions on messages`.

### Task 4: Merge duplicate direct chats

**Files:**
- Modify: `ฝากงาน/index.html` (`startDirectChat`)

**Interfaces:**
- Consumes: `state.chats`, `me()`, `db`.
- Produces: `mergeDuplicateDirectChats(username)` returning the kept chat id.

- [ ] **Step 1: Write the failing test** — `task4-test.sh` asserts `mergeDuplicateDirectChats`, `sortedDuplicates`.
- [ ] **Step 2: Run it; expected FAIL.**
- [ ] **Step 3: Implement** — in `startDirectChat`, find all direct chats containing both users; sort by `createdAt`; keep the oldest; for each extra, delete its message docs then the chat doc; remove them from `state.chats`; save and open the kept chat.
- [ ] **Step 4: Run test; expected PASS; commit** `fix: merge duplicate direct chats`.

### Task 5: Desktop bottom bar with hover hint

**Files:**
- Modify: `ฝากงาน/index.html` (CSS in `@media (min-width: 768px)`, `mousemove` listener in `init`)

**Interfaces:**
- Consumes: existing `.nav-bar`, `#nav-root`, `isDesktopNav()`.
- Produces: `.nav-hint`, `.nav-bar.is-near`.

- [ ] **Step 1: Write the failing test** — `task5-test.sh` asserts `nav-hint`, `is-near`, and that `#app { padding-left: 76px; }` is absent.
- [ ] **Step 2: Run it; expected FAIL.**
- [ ] **Step 3: CSS** — remove the vertical rail rules and `#app` padding; restore `.nav-bar` to `left/right 12px; bottom 12px; height 68px; flex-direction row`; default `transform: translateY(140%); opacity: 0; pointer-events: none;` with `.is-near` restoring them; add a small fixed `.nav-hint` strip at bottom centre, visible only on desktop.
- [ ] **Step 4: JS** — change the existing `mousemove` near-test to `e.clientY > window.innerHeight - 120 || bar.contains(e.target)`; keep `mouseleave` clearing `is-near`.
- [ ] **Step 5: Run test; expected PASS; commit** `feat: desktop bottom nav with hover hint`.

### Task 6: Final verification and deploy

**Files:**
- Modify: `fakjob-pages/index.html`, `README.md`

- [ ] **Step 1: Write the failing test** — `task6-test.sh` asserts latest commit message, clean tree, and all five feature markers in `index.html`.
- [ ] **Step 2: Run it; expected FAIL.**
- [ ] **Step 3: Deploy** — copy source, update README with the new chat tools, commit, push.
- [ ] **Step 4: Run test; expected PASS; check `gh api repos/Sigmamewingbyebye/fakjob/pages --jq '.status'`; commit/push if README changed after.**
