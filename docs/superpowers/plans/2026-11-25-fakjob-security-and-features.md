# fakjob Security Lock-down and Daily-Use Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace public Firestore access with Firebase Auth plus ownership rules, then add due-date badges, comment edit/delete and job search.

**Architecture:** Static one-file HTML app on GitHub Pages. Firebase Auth (compat SDK) supplies `request.auth.uid`; Firestore rules enforce ownership on account, job, comment, chat and message documents. Public profile data is mirrored to `publicProfiles/{username}` so `passwordHash` and `authEmail` never leave the owner. A features layer on top computes badges and filters `state.jobs` in memory.

**Tech Stack:** HTML/CSS/vanilla JS, `firebase-app-compat.js`, `firebase-auth-compat.js`, `firebase-firestore-compat.js` v10.12.2 from gstatic, Firestore REST + Identity Toolkit REST for one-time migration, curl/git/gh for deploy.

**Spec:** `docs/superpowers/specs/2026-11-25-fakjob-security-and-features-design.md`

## Global Constraints

- Working source: `/storage/emulated/0/ฝากงาน/index.html`; deploy copy: `/storage/emulated/0/fakjob-pages/index.html`; repo `Sigmamewingbyebye/fakjob`, branch `main`, Pages URL `https://sigmamewingbyebye.github.io/fakjob/`.
- Firebase project `fakjob-1211f`; Web API key `AIzaSyBpsJajZOYI2cdgBLPMiXO0Otjnd-0PvAE`; Firestore database `(default)`.
- Synthetic Auth email: `<username>@fakjob.local`; migrated-account temporary password: `Fakjob@1234`; migrated accounts carry `mustChangePassword: true`.
- Firestore document limit 1 MiB; images are compressed to ≤650,000-character data URLs before writing.
- One HTML file only — no backend, no build step, no new npm packages.
- Deploy pattern: copy source to deploy copy, `git add`, `git commit`, `git push origin main`.
- Do not expose `passwordHash` or `authEmail` in `publicProfiles`.

## Review Focus

1. **Signed-out read/write** — a visitor without Firebase Auth must get `PERMISSION_DENIED` on every Firestore collection. Test: Task 4 step 2.
2. **Migrated account first login** — old username + temp password must sign in, then force a password change before normal use. Test: Task 3 step 4.
3. **Legacy comments without `authorUid`** — still visible, never editable/deletable by anyone. Test: Task 7 step 2.
4. **Cross-user tampering** — user A cannot delete or edit user B's job, account or profile; a non-member cannot read private chat messages. Comment edit/delete is restricted in the UI by `authorUid` while the rule permits only the `comments` field to change, so a crafted client could still tamper with comments — accepted limitation, recorded in the plan. Test: Task 4 step 4 and Task 5 step 4.
5. **Oversize image** — banner/profile/chat images stay under the 1 MiB Firestore document cap. Test: Task 8 step 2.

---

### Task 1: Firebase Auth SDK and auth helpers

**Files:**
- Modify: `ฝากงาน/index.html` (head script tags; globals near `FIREBASE_CONFIG`; helpers after `initFirestore`)

**Interfaces:**
- Consumes: `FIREBASE_CONFIG`, `db`, `cloudReady`, `initFirestore()` from existing code.
- Produces: `auth`, `authUser`, `authReady`, `authEmailFor(username)`, `signInUser(username, password) -> Promise<user>`, `createUser(username, password) -> Promise<user>`, `changeOwnPassword(newPassword) -> Promise<void>`, `signOutUser() -> Promise<void>`.

- [ ] **Step 1: Load the Auth compat SDK**

Add `<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"></script>` next to the existing app/firestore script tags in `<head>`.

- [ ] **Step 2: Initialise Auth in `initFirestore()`**

After `db = app.firestore()`, set `auth = app.auth()`, `authUser = auth.currentUser`, and register `auth.onAuthStateChanged((u) => { authUser = u; authReady = true; })`. Declare `let auth = null; let authUser = null; let authReady = false;` and `let authEmailFor = ...` as a function returning `encodeURIComponent(username) + '@fakjob.local'`.

- [ ] **Step 3: Implement the five auth helpers**

`signInUser` → `auth.signInWithEmailAndPassword(authEmailFor(username), password)`; `createUser` → `auth.createUserWithEmailAndPassword(...)`; `changeOwnPassword` → `authUser.updatePassword(newPassword)`; `signOutUser` → `auth.signOut()`. Each returns the SDK promise.

- [ ] **Step 4: Verify syntax and commit**

Run: `grep -n "firebase-auth-compat\|function signInUser\|onAuthStateChanged" /storage/emulated/0/ฝากงาน/index.html`
Expected: all three present.
Then copy `ฝากงาน/index.html` to `fakjob-pages/index.html`, commit there with `git add index.html && git commit -m "feat: add Firebase Auth SDK and helpers"`.

---

### Task 2: Migrate existing accounts to Firebase Auth and public profiles

**Files:**
- Create: `fakjob-pages/docs/superpowers/migration-2026-11-25.md` (records what was run and the counts)
- External: Firebase Auth + Firestore (via `execute` with the Web API key)

**Interfaces:**
- Consumes: existing `accounts/{username}` docs holding `username`, `name`, `passwordHash`, `profilePic`, `profileBanner`, crops, `followedRooms`, `likedIds`.
- Produces: Auth users `<username>@fakjob.local` with temp password `Fakjob@1234`; `publicProfiles/{username}` docs containing `uid`, `name`, `profilePic`, `profileBanner`, `profilePicCrop`, `profileBannerCrop`, `followedRooms`; account docs gain `authEmail`, `uid`, `mustChangePassword: true`.

- [ ] **Step 1: Inventory the seven existing account docs**

Run a Firestore REST list of `accounts` and record the usernames. Expected: `K`, `Nikka01`, `admin`, `beta tester`, `main`, `t`, `uwu_67`.

- [ ] **Step 2: Create Auth users via Identity Toolkit REST**

For each username call `POST https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=<API_KEY>` with `{email, password: "Fakjob@1234", returnSecureToken: true}`. Skip with a logged note if the email already exists. Store each returned `localId` as `uid`.

- [ ] **Step 3: Write `publicProfiles` and patch account docs**

For each username: `PATCH .../documents/publicProfiles/<url-encoded-username>` with the public fields plus `uid`; `PATCH .../documents/accounts/<url-encoded-username>` with `authEmail`, `uid`, `mustChangePassword: true` using `updateMask` where practical. Drop profile images longer than 650,000 characters.

- [ ] **Step 4: Verify the migration**

Run `POST https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=<API_KEY>` for the seven synthetic emails and a Firestore list of `publicProfiles`. Expected: 7 Auth users and 7 profile docs, no `passwordHash` or `authEmail` in any profile doc. Record counts in the migration markdown and commit it.

---

### Task 3: Login, signup and forced password change

**Files:**
- Modify: `ฝากงาน/index.html` (`onLoginSubmit`, `onSignupSubmit`, new `renderChangePasswordHtml`/`bindChangePassword`, `render` switch, `init`)

**Interfaces:**
- Consumes: Task 1's `signInUser`, `createUser`, `changeOwnPassword`, `authUser`, `authEmailFor`; existing `hashStr`, `BOOTSTRAP_ACCOUNT`, `saveState`, `go`, `render`.
- Produces: screen `'changePassword'`; helper `finishAuth(account, payload)` that sets `state.account`, `syncUser`, `navTab='home'`, `screen='home'`, `saveState()`, `render()`, `applyPendingJoin()`.

- [ ] **Step 1: Rewrite login to use `signInUser`**

`onLoginSubmit` calls `await signInUser(username, password)`; on success loads `accounts/{username}` and `publicProfiles/{username}` docs, merges into `state.account`, then routes to `'changePassword'` when `mustChangePassword` is true, otherwise `finishAuth`.

- [ ] **Step 2: Rewrite signup to use `createUser`**

`onSignupSubmit` calls `createUser`, then writes `accounts/{username}` with `uid = authUser.uid`, `authEmail`, `mustChangePassword: false`, and a `publicProfiles/{username}` doc. Field set matches Task 2.

- [ ] **Step 3: Add the password-change screen**

`renderChangePasswordHtml` shows one password field (`id="new-password"`, min length 6) and a save button; `bindChangePassword` calls `changeOwnPassword`, patches `mustChangePassword: false` on the account doc, then `finishAuth`.

- [ ] **Step 4: Verify the migrated-account flow**

Log in as `admin` with `Fakjob@1234` → expect the password-change screen; set a new password → expect Home. Sign out and log in with the new password → expect Home directly. Record the result in the plan's execution notes; commit.

---

### Task 4: Publish Firestore rules and verify access

**Files:**
- Create: `fakjob-pages/firestore.rules`
- External: Firebase Console → Firestore → Rules → Publish

**Interfaces:**
- Consumes: `request.auth.uid` from Firebase Auth; doc fields from Tasks 2–3 (`postedByUid`, `authorUid`, `members`, `privacy`, `uid`).
- Produces: published rules; verification notes in `docs/superpowers/migration-2026-11-25.md`.

- [ ] **Step 1: Write the rules file**

Rules must include helpers `signedIn()` and `isMember(chatId)` using `get(/databases/$(database)/documents/chats/$(chatId))`. Access:
`accounts/{id}` owner only; `publicProfiles/{username}` read signed-in, write only when `request.resource.data.uid == request.auth.uid`; `jobs/{id}` read signed-in, create requires postedByUid match, update/delete owner only; `chats/{id}` read member or public, create requires self in members, update only member or self-join/self-leave with `affectedKeys().hasOnly(['members'])`; `messages/{id}` read/write member only.

- [ ] **Step 2: Verify signed-out access fails**

Run a Firestore REST GET on `accounts/admin` with only the Web API key (no Auth header). Expected: `PERMISSION_DENIED`. Repeat for `jobs` and `chats`.

- [ ] **Step 3: Publish the rules**

Paste `firestore.rules` into Firebase Console → Firestore Database → Rules → Publish (demo public rules are replaced). Wait for status `Published`.

- [ ] **Step 4: Verify cross-user tampering fails**

With Auth token for user A, attempt `PATCH jobs/<user-B-job>` and `DELETE accounts/<user-B>` via REST. Expected: `PERMISSION_DENIED` for both. With the same token, a member write to `chats/<own-chat>/messages/<id>` must succeed. Commit the rules file.

---

### Task 5: App writes and reads use ownership fields

**Files:**
- Modify: `ฝากงาน/index.html` (`cloudPush`, `startCloudListeners`, `renderJobCardHtml`, `renderJobDetailHtml`, `sendComment`, `openProfileView`, `setViewProfile`, `chatMetaOf`, `toggleJoinGroup`, `leaveGroupChat`, `startDirectChat`, `createGroupChat`)

**Interfaces:**
- Consumes: Task 1 `authUser`; Task 4 rules; existing `state`, `pushedJobs`, `pushedChats`, `pushedMsgs`.
- Produces: every job doc carries `postedByUid`; every comment carries `authorUid`; every account/profile doc carries `uid`; other users' profile data read from `publicProfiles`.

- [ ] **Step 1: Add uid fields at creation points**

`job.postedByUid = authUser.uid` in the add-job submit path; comment `authorUid = authUser.uid` in `sendComment`; `uid = authUser.uid` in account and public-profile writes. Existing docs lacking uid are readable but remain uneditable.

- [ ] **Step 2: Read other users' profiles from `publicProfiles`**

Change `startCloudListeners` to keep a `publicProfiles` map; point `knownAccounts`/`knownRows` at it for non-self profiles; keep full `accounts/{self}` for own account only.

- [ ] **Step 3: Remove personal fields from group and job payloads**

`chatMetaOf` writes only the five fields which the rules allow; job writes drop `updated_at`; profile mirror never includes `passwordHash` or `authEmail`.

- [ ] **Step 4: Verify ownership fields and commit**

Run: `grep -n "postedByUid\|authorUid\|publicProfiles" /storage/emulated/0/ฝากงาน/index.html`
Expected: all three present. Attempt to edit a remote job as another user via the UI → no delete button for non-owner. Commit.

---

### Task 6: Due-date badges and job search

**Files:**
- Modify: `ฝากงาน/index.html` (`renderJobCardHtml`, `renderHomeHtml`, `renderHistoryHtml`, `bindHome`, `bindHistory`, CSS near `.job-card__status`)

**Interfaces:**
- Consumes: `state.jobs`, `statusOf(job)`, `homeTypeFilter`, `homeSubjectFilter`.
- Produces: helper `dueBadge(job) -> string`, `jobSearch = ''`, helper `matchesSearch(job) -> boolean`.

- [ ] **Step 1: Implement `dueBadge(job)`**

Return `''` when no `dueDate`; `'เลยกำหนด'` when past; `'ครบกำหนดวันนี้'` when equal to today; `'ใกล้กำหนด · ' + fmtDate(dueDate)` when 1–3 days away. Build today's string from local parts: `[d.getFullYear(), String(d.getMonth()+1).padStart(2,'0'), String(d.getDate()).padStart(2,'0')].join('-')`.

- [ ] **Step 2: Render the badge on job cards**

Add `<span class="job-card__due">...</span>` beside `job-card__status` when `dueBadge` is non-empty; add CSS tone classes for `due-warn` and `due-over`.

- [ ] **Step 3: Add the search field**

On home and history, add `<input id="job-search" type="search" placeholder="ค้นหางาน">`; store `jobSearch` on input; `matchesSearch` lowercases title, content, subject and `postedByName` and returns true when `jobSearch` is empty. Apply it inside the existing `.filter(...)` chains without replacing type/subject filters.

- [ ] **Step 4: Verify and commit**

Run: `grep -n "dueBadge\|job-search\|matchesSearch" index.html`
Expected: all present. In the browser, type a known job title into search on Home and History → only matching cards remain. Commit.

---

### Task 7: Comment edit and delete

**Files:**
- Modify: `ฝากงาน/index.html` (`renderJobDetailHtml` comment markup, `bindJobDetail`, `sendComment`, CSS near `.comment-author`)

**Interfaces:**
- Consumes: `authUser`, Task 5 `authorUid`; Firestore rules from Task 4.
- Produces: helpers `canEditComment(c) -> boolean`, `patchComment(jobId, commentId, patch) -> Promise<void>`, `removeComment(jobId, commentId) -> Promise<void>`.

- [ ] **Step 1: Render actions only for owned comments**

`canEditComment` returns true only when `c.authorUid && authUser && c.authorUid === authUser.uid`. For owned comments render `data-comment-edit` and `data-comment-delete` buttons; legacy comments stay visible with no actions.

- [ ] **Step 2: Verify legacy comments are not editable**

Seed one comment without `authorUid` → open the job detail → no edit/delete buttons for it; call `canEditComment` mentally with `authorUid` undefined → false. Record in execution notes.

- [ ] **Step 3: Implement edit and delete**

Keep the existing `comments` array inside the job document (the spec forbids new collections). `patchComment` and `removeComment` call `db.collection('jobs').doc(jobId).update({ comments: nextArray })`; the UI guard from step 1 is the ownership enforcement, and the rule limits job updates by non-owners to `affectedKeys().hasOnly(['comments'])`. Record the crafted-client limitation in the execution notes. `editedAt` is set on edit so the bubble can show `แก้ไขแล้ว`.

- [ ] **Step 4: Verify ownership and commit**

As user A, open a job by user B → cannot edit/delete B's comments. As the comment author, edit text → updated bubble shows `แก้ไขแล้ว`; delete → bubble disappears. Commit.

---

### Task 8: Final verification and deploy

**Files:**
- Modify: `fakjob-pages/index.html` (copy from source)
- Modify: `fakjob-pages/README.md` (note Auth requirement and first-login password change)

**Interfaces:**
- Consumes: all prior tasks.
- Produces: pushed commit; live Pages build.

- [ ] **Step 1: Verify oversize-image guard**

Upload a banner from a large PNG on the profile page → crop screen appears → save → Firestore account doc size must stay under 1 MiB (check with REST `GET` and byte length of `profileBanner`). Expected: write succeeds, no `PERMISSION_DENIED`.

- [ ] **Step 2: Verify signed-out app behaviour**

Open the Pages URL in a logged-out browser session → login screen appears; Firestore REST without Auth still denies reads.

- [ ] **Step 3: Deploy**

Run: `cp /storage/emulated/0/ฝากงาน/index.html /storage/emulated/0/fakjob-pages/index.html && git add index.html README.md && git commit -m "feat: lock down Firestore with Auth and add due badges, search, comment editing" && git push origin main`.

- [ ] **Step 4: Confirm Pages and commit**

Run: `gh api repos/Sigmamewingbyebye/fakjob/pages --jq '.status + " " + .html_url'` and `gh api repos/Sigmamewingbyebye/fakjob/commits/main --jq '.[0:7]'`. Expected: build status present and the new commit on `main`.
