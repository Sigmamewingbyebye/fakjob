# Chat tools and desktop nav design

Date: 2026-11-26

## Intent

Add three chat tools requested by the human partner, restore the desktop
bottom navigation bar with a hover hint, and fix duplicate direct chats
between the same two people.

## Goals

- Hide a chat from the current account only; nobody else is affected.
- Reply to a message with a quoted bubble.
- React to a message with an emoji, counted by user uid.
- Desktop nav is horizontal at the bottom again; it appears only when the
  mouse is near, with a persistent subtle hint that it exists.
- Opening a direct chat with a person always reuses the same chat.

## Non-goals

- Deleting chat documents or messages for everyone.
- New Firestore rules / re-publishing rules.
- Changing group create/join/invite-link behaviour.
- Push notifications.

## Constraints

- Single-file static HTML app on GitHub Pages.
- Firestore: chats at `chats/{id}`, messages at `chats/{id}/messages/{id}`.
- Current rules: signed-in users may read/write chat and message docs;
  account doc readable/writable only by its `uid`.
- Chat membership is stored as usernames; `me()` is the username.
- Reacting is counted by Firebase Auth uid (`authUser.uid`).
- No new collections; all changes are fields on existing docs.

## Approaches

- **Hide chat:** store `hiddenChatIds` in the owner's `accounts/{username}`
  doc and filter it out of `renderChatHtml`. Chosen — works with the
  existing owner-only account rule, no rule publish needed. Rejected:
  deleting docs (affects everyone) and a per-user subcollection (new rules).
- **Reply:** add `replyTo: {id, sender, text}` to the message doc and render
  a quoted line inside the bubble; clicking it scrolls to/highlights the
  original message. Chosen — a field on an existing doc, no new model.
- **Reactions:** add `reactions` map `{emoji: [uid, ...]}` to the message
  doc; show count badges under the bubble. Chosen — toggling an array by
  uid is an `update()` on one doc, allowed by current rules.
- **Desktop nav:** revert the CSS to a bottom-centred horizontal bar,
  hidden with `translateY(140%) + opacity 0`, revealed on `mousemove` when
  the pointer is within ~120px of the bottom or over the bar. Add a thin
  always-visible "hint" strip at bottom centre. Chosen — CSS plus the
  existing `mousemove` listener; no structural change.
- **Duplicate direct chats:** `startDirectChat` currently searches
  `state.chats` for a direct chat containing both users. When several
  already exist, pick the oldest by `createdAt`, delete the extra chat
  metadata docs (and their messages), then open the kept one. Chosen —
  repairs existing data as well as preventing future duplicates.

## Decisions (builder's calls)

- Emoji set: `❤️ 👍 😂 😮 😢`; one reaction per user per emoji; tapping the
  same emoji again removes it.
- Reply bubble shows sender name plus first 80 characters of the original
  text; legacy messages without `replyTo` render unchanged.
- Hidden chats remain only in the account doc; `hydrateChats` and the
  chats listener both apply the filter.
- Only the current user's reaction state affects the highlighted emoji.
- The desktop hint strip is decorative and click-through; the bar itself
  remains the interactive element.

## What is left to the builder

- Write the implementation plan (invoke `writing-plans`) and execute it.
- Verify with grep/REST assertions that the data fields and UI hooks exist;
  no JS test runner is available in this environment.
- Deploy by copying `ฝากงาน/index.html` to `fakjob-pages/index.html`,
  committing and pushing to `main`.
