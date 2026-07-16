# Firestore recipe change - security analysis

Date: 2026-07-14

This working document is intentionally untracked. It records the codebase scan
and red-team review performed before changing `firestore.rules`.

## Codebase scan

- Languages: Dart/Flutter client, TypeScript Cloud Functions, JavaScript rules tests.
- Authentication: Firebase Auth (email/password, Google, anonymous). Client access is
  gated by `request.auth`; roles are read from `userProfiles/{uid}`.
- Top-level collections referenced by the application: `userProfiles`, `users`,
  `products`, `recipes`, `inviteCodes`, `scheduled_follow_ups`, `careerRoadmap`,
  `programs`, `motivations`, `motivation_scores`, and `notification_debug`.
- User subcollections referenced: `customers`, `follow_ups`, `orders`,
  `progressEntries`, `waterLogs`, `waterSummaries`, `calorieLogs`, `dailyRoutines`,
  `program`, and `daily_exercise`.
- Existing queries use equality/range filters, `whereIn`, document-id ranges,
  ordering and limits. The new recipe query is an unfiltered real-time collection
  snapshot (`recipes.snapshots()`), so its rule must permit authenticated list/read.
- Recipe documents contain catalog content, not PII. Fields consumed by the client:
  `productId`, `title`, `description`, optional media URLs, `prepTimeMin`, `calories`,
  `goals`, `tags`, `ingredients`, `steps`, optional `nutritionInfo`, optional `tips`,
  and `isRecommended`. The Firestore document id is the canonical recipe id.
- Recipe client CRUD: read/list only. Writes are performed through Firebase Console
  or an Admin SDK, both of which bypass client Security Rules.

## Recipe rule attack review

1. Public list exploit: blocked; unauthenticated reads fail.
2. Unauthorized read: authenticated users can read by design; catalog has no PII.
3. Unauthorized create/update/delete: blocked for every mobile/web client role.
4. Update bypass/schema pollution/type juggling/1 MB writes: blocked because all
   client writes are denied, so a validator is not reachable or required.
5. Ownership/role escalation: recipe documents carry no owner or authority fields.
6. Immutable-field/timestamp manipulation: blocked because client updates are denied.
7. Query mismatch: authenticated unfiltered collection reads match the new listener.
8. Offline behavior: Firestore cache and bundled JSON remain readable; neither grants
   write authority.

## Auditor result

```json
{
  "score": 5,
  "summary": "The new recipes rule is least-privilege for a non-PII catalog: authenticated read/list only and no client writes.",
  "findings": []
}
```

## Existing rule-set observation outside this change

The pre-existing `match /users/{userId} { allow read, write: if isOwner(userId); }`
is broader than the validators on its nested data model and merits a separate full
hardening pass. It was not widened by this recipe change.

## Distributor recipe creation update

- Mobile clients now create, but never update or delete, recipe documents.
- Authority comes from the existing `userProfiles/{uid}.role` lookup; the role is
  not supplied by the recipe form.
- The new `isValidRecipe` validator is used by every permitted client write
  operation (create). It restricts the exact schema, string lengths, URLs,
  numeric ranges, list sizes, Formula 1 product id, and nutrition map shape.
- Red-team checks: unauthenticated/customer creates, malformed schema, negative
  calories, oversized values, update bypasses, and delete attempts are expected
  to fail. Authenticated distributor creation with a valid document is expected
  to succeed.
# Favoriler güvenlik denetimi

Favoriler `userProfiles/{uid}/favorites/{type}_{itemId}` altında saklanır. Alt koleksiyon
yalnızca ilgili oturum sahibinin okuma, oluşturma ve silme işlemlerine açıktır; güncelleme
izinli değildir. Belge kimliği, tür ve öğe kimliğiyle zorunlu olarak eşleşir. Böylece bir
kullanıcının başka bir kullanıcının favorilerini okuması veya yazması; ya da ürün/tarif
dışında bir türle beklenmeyen veri oluşturması engellenir.
