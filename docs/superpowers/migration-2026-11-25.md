# Migration 2026-11-25 — Firebase Auth + publicProfiles

Run after enabling Authentication → Email/Password and adding the authorized
domain `sigmamewingbyebye.github.io`.

**Result:** 7/7 accounts migrated.

| username | Auth email | uid |
|---|---|---|
| K | K@fakjob.local | dN0lxZcOqMeyh5swbbS31dMA9BS2 |
| Nikka01 | Nikka01@fakjob.local | XiQJmI9FsqTWB1seYKiceBOPnAv2 |
| admin | admin@fakjob.local | SFWEFSJsmnSN7fGKXg1W7MOABwa2 |
| beta tester | beta%20tester@fakjob.local | cG4vmd90tqMw8r1NInGuFY1w6wp1 |
| main | main@fakjob.local | scovcRNAvLgRdVkeWE3CEKDqJks1 |
| t | t@fakjob.local | sbpxHcTRDUP7QtGloTUQNXyphHs1 |
| uwu_67 | uwu_67@fakjob.local | kL9bQIojEFdjZ4uNwpP7Uo4UNyo2 |

Each account doc gained `authEmail`, `uid`, `mustChangePassword: true`.
Each `publicProfiles/{username}` doc holds `uid`, `name`, `profilePic`,
`profileBanner`, `profilePicCrop`, `profileBannerCrop`, `followedRooms` only —
no `passwordHash` or `authEmail`.

Temporary password for every migrated account: `Fakjob@1234`.
The app must force a password change on first login.

Test (RED → GREEN): `task2-test.sh` — before migration 0 profiles / no Auth user;
after migration 14 profile-name matches, no private fields, admin sign-in works.

Ruling: the plan's `accounts:lookup` verification fails with `MISSING_ID_TOKEN`
when called with only a Web API key, so the test verifies the Auth user via
`accounts:signInWithPassword` instead. Cost: proves the temp password works,
which is what the migration needs.
