# P8 Firestore Invite Code Security Analysis

Date: 2026-07-19

## Target

- Firebase project: `herbaformix`
- Database: `(default)`
- Edition/type: Standard, Firestore Native
- Region: `eur3`

## Access-path findings

The Flutter application uses typed repositories for `userProfiles`, nested
`users/{uid}` data, products, recipes, programs, orders, progress, water,
scheduled follow-ups, notifications, and invite codes. Query shapes were
enumerated from `lib/` and `functions/src/`; the P8 change is scoped to the
invite-code paths so unrelated active notification work remains untouched.

Invite-code workflows use these paths atomically:

- `inviteCodes/{code}`: private lifecycle document. It can contain customer
  name, phone, and email.
- `inviteCodeLookups/{code}`: new PII-free exact-id lookup document.
- `userProfiles/{customerUid}`: assigned distributor and connection code.
- `users/{distributorUid}/customers/{customerId}`: customer link activation.

The app performs exact-id validation, distributor-scoped list queries, create,
claim, expire, and delete operations. A Firestore rule cannot hide individual
fields in a readable document, so allowing every signed-in user to get an
`inviteCodes` document leaked all PII stored in that document.

## Security design

1. Private invite documents are readable only by their distributor or the user
   who claimed the code.
2. Exact-code validation reads a separate strict-schema lookup document that
   contains no name, phone, or email. Collection listing is denied.
3. Private and lookup documents must be created, claimed, expired, and deleted
   together in one batch. Rules use post-write state checks to reject one-sided
   writes and update bypasses.
4. Both validators enforce allowed/required fields, types, string sizes,
   status values, code format, timestamp ordering, and used/status consistency.

## Devil's-advocate checks

- Public/unauthenticated lookup: denied.
- Lookup collection enumeration: denied.
- Unrelated authenticated read of private PII: denied.
- Private-only or lookup-only create/claim: denied.
- Claiming a code for another UID: denied.
- Adding PII or arbitrary fields to lookup: denied.
- Invalid status/isUsed combinations: denied by validators.
- Oversized identifiers and contact fields: denied by size limits.
- Distributor list queries remain supported by owner-constrained private reads.

## Migration note

Existing production invite documents need matching PII-free lookup documents
before those legacy codes can be validated through the new client path. New,
renewed, claimed, expired, and deleted codes remain synchronized automatically.

Use `npm --prefix functions run migrate:invite-lookups` for a read-only preview.
After reviewing the output and arranging a backup/rollout window, append
`-- --apply` to normalize legacy UUID documents and write their lookup records.
