# Distributor role workflow – Firestore analysis

## Scope

- Flutter client uses Firebase Auth and Cloud Firestore.
- Cloud Functions use the Admin SDK and Firebase Functions v1.
- Active database: `projects/herbaformix/databases/(default)`, Standard Edition,
  Firestore Native, `eur3`.

## Existing data and access paths

- `userProfiles/{uid}` stores the authenticated user's role, assigned
  distributor, distributor request state, FCM token and private profile data.
- `users/{uid}/notifications/{notificationId}` is server-written and owner-read.
- `users/{distributorUid}/customers/{customerId}` stores the distributor CRM
  record and links to `userProfiles/{customerUid}` through `linkedUserId`.
- Customer profiles are queried by `assignedDistributorId == distributorUid`.
- Notification inbox entries are queried by `createdAt desc` and limited to 100.

## Existing workflow defects

- A customer only changed `userProfiles.distributorRequestStatus` to `pending`.
- No server trigger notified the assigned distributor.
- Approval attempted to change `userProfiles.role` directly from the Flutter
  client, which the current rules correctly reject.
- The app did not verify that the applicant had an assigned distributor.
- `AuthProvider` loaded a profile once and did not react to server-side role
  changes while the app remained open.

## New write model

### `roleChangeActions/{requestedBy}_{customerId}`

Server command document written by a distributor client and consumed/deleted by
Cloud Functions.

- `requestedBy`: string, required, authenticated distributor UID, max 128.
- `customerId`: string, required, assigned customer UID, max 128.
- `action`: string, required, `promote` or `demote`.
- `createdAt`: timestamp, required, recent (within five minutes).

Clients may only create a command for a profile whose
`assignedDistributorId == request.auth.uid`. Promotion requires customer role +
pending request. Demotion requires distributor role + approved request. Clients
cannot read, update, or delete commands. Cloud Functions re-check all authority
and transition constraints in a transaction before changing the role.

## State transitions

- Customer application: absent/cancelled/rejected/reverted -> pending.
- Distributor promotion (server): assigned customer, with or without a request,
  -> distributor + approved.
- Distributor correction (server): distributor + approved -> customer + reverted.

No client is allowed to write a privileged role directly.

## Notification behavior

- `userProfiles` transition to `pending` creates an inbox notification and,
  when a token exists, an FCM push for the assigned distributor.
- Successful promotion/demotion creates an inbox notification for the affected
  user and attempts FCM delivery.
- Stable notification IDs make retries idempotent.

## Index impact

The new command path is document-create only and has no client query. No new
composite index is required.

## Devil's advocate results

1. Public list exploit: blocked; `roleChangeActions` has no client read/list.
2. Unauthorized CRUD: only the assigned authenticated distributor can create;
   all client reads, updates, and deletes are denied.
3. Update bypass: blocked because client updates are unconditionally denied.
4. Ownership hijacking on create: blocked by `requestedBy == request.auth.uid`,
   deterministic document ID, and assigned-distributor lookup.
5. Ownership hijacking on update: not applicable; updates are denied.
6. Immutable field modification: not applicable; updates are denied.
7. Type juggling: blocked by explicit string/timestamp validators.
8. Create-vs-update validation bypass: blocked; there is no update path.
9. Resource exhaustion: all command strings are enum-constrained or capped at
   128 characters; extra fields are rejected.
10. Required field omission: blocked by `keys().hasAll()`.
11. Privilege escalation: customers cannot create commands and no client can
    update `userProfiles.role`; the Admin function re-checks actor authority.
12. Schema pollution: blocked by `keys().hasOnly()` and emulator test.
13. Invalid state transition: promote requires an assigned customer; demote
    requires distributor+approved. Both are re-checked in the server transaction.
14. Path traversal/scoping: no path field is accepted; customer ID is checked
    against the exact assigned profile relationship.
15. Timestamp manipulation: command timestamp must be no more than five minutes
    old and cannot be in the future.
16. Negative/overflow values: no numeric input exists.
17. Mixed-content leak: command documents are unreadable; existing profile read
    remains limited to owner/assigned distributor.
18. Counter/action replay: deterministic action IDs prevent concurrent duplicate
    creates; state-transition checks reject a replay after processing.
19. Orphan access: create requires an existing target profile.
20. Query mismatch: no client query is used for the command collection.
21. Validator pattern: create calls `isValidRoleChangeAction`; update is denied.

Emulator coverage confirms the valid application/promotion/demotion paths and
rejects unassigned applications, arbitrary approval, cross-distributor writes,
customer-created commands, command reads, and schema pollution.
