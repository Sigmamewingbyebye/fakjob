# fakjob — Security lock-down and daily-use features

Date: 2026-11-25

## Intent

Two pieces of work the human partner selected:

- **B (do first):** stop anyone with the GitHub Pages link from reading/writing all data.
- **A (do second):** add small features that make the app nicer day to day.

Reason: the app is about to be usable enough to share with classmates. Today
Firestore rules are `allow read, write: if true`, so any visitor can delete jobs,
chat messages and accounts. The features in A (especially editing/deleting one's
own comments) need a trustworthy identity, so B comes first.

## Goals

### B — Security
- Every read/write requires a signed-in Firebase Auth user.
- A user can modify only their own account, jobs and comments.
- Chat metadata and messages are readable/writable only by group members;
  public groups may be read by any signed-in user and joined via invite link.
- Existing usernames and history are preserved.

### A — Features
- Due-date state on job cards: `เลยกำหนด`, `ครบกำหนดวันนี้`, `ใกล้กำหนด (≤3 วัน)`.
- Edit/delete one's own comments inside job detail.
- Search jobs by title/content/subject from home and history.

## Non-goals

- Email verification, password reset emails, admin/moderation UI.
- Push notifications — the due-date work is an in-app badge only.
- Changing the one-file static HTML architecture or moving off GitHub Pages.
- Reworking chat/group UI beyond what A and B require.

## Constraints

- Single `index.html`, no backend, hosted on GitHub Pages.
- Firebase project `fakjob-1211f`, Firestore `(default)`, public demo rules today.
- 7 existing accounts in `accounts/{username}` with `passwordHash = hashStr(plain)`;
  plaintext passwords are not recoverable.
- Firestore document limit 1 MiB; images are already compressed before upload.
- Users know each other by username, not email.

## Approaches

### Identity (B)
1. **Firebase Auth email/password with synthetic email** — `<username>@fakjob.local`.
   Native `request.auth.uid` makes ownership rules short and real. Usernames stay
   unchanged. Existing accounts get an Auth user with a temporary password and a
   `mustChangePassword` flag; the app forces an in-app password change on first login.
   **Chosen.**
2. Keep the custom passwordHash login and issue custom tokens via Cloud Functions.
   Preserves passwords exactly, but requires a backend, breaking the static one-file
   constraint. Rejected.
3. App Check with public rules. Easy, but cannot identify a user, so it cannot
   enforce ownership. Rejected.

### Features (A)
1. Extend the existing render functions and Firestore docs — badges are computed
   from `dueDate`; comments get `authorUid` and `editedAt`; search filters the
   already-loaded `state.jobs` in memory. No new collections. **Chosen.**
2. Server-side queries/Firestore indexes for search. Unnecessary at this data size
   and would need indexes plus more complex rules. Rejected.

## Decisions (builder's calls where the human partner did not specify)

- Order: B first, then A.
- Auth email mapping: `encodeURIComponent(username) + '@fakjob.local'` stored in the
  account doc as `authEmail` for reference.
- Temporary password for migrated accounts: `Fakjob@1234`, with forced change.
- Rules shape:
  - `accounts/{id}`: read own full doc; other signed-in users may read only public
    fields via a separate `publicProfiles/{username}` mirror doc to avoid exposing
    `passwordHash` and `authEmail`.
  - `jobs/{id}`: read if signed in; create requires `postedByUid == request.auth.uid`;
    update/delete only by owner.
  - `chats/{id}`: read/write if `request.auth.uid in members` or `privacy == 'public'`.
  - `chats/{id}/messages/{id}`: same membership check as parent.
- `publicProfiles/{username}` mirror holds `name`, `profilePic`, `profileBanner`,
  `profilePicCrop`, `profileBannerCrop`, `followedRooms`. Written by the owner only.
- Comment ownership uses `authorUid`; legacy comments fall back to `authorUser`
  username for display but cannot be edited.
- Search is a local filter over `state.jobs`; no index needed.

## What is left to the builder

- Write the implementation plan (invoke `writing-plans`) and execute it.
- After B, verify with signed-out and signed-in requests that public access fails.
- Keep the app working offline from localStorage as today.
- Deploy by copying `ฝากงาน/index.html` to `fakjob-pages/index.html`, commit, push.
