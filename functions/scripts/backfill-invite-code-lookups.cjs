const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const shouldApply = process.argv.includes('--apply');
const codePattern = /^[A-Z0-9]{8}$/;

function lookupData(privateData, code) {
  return {
    code,
    distributorId: privateData.distributorId,
    createdAt: privateData.createdAt,
    expiresAt: privateData.expiresAt,
    status: privateData.status ?? (privateData.isUsed ? 'used' : 'pending'),
    isUsed: privateData.isUsed === true,
    ...(typeof privateData.usedByUserId === 'string' &&
    privateData.usedByUserId.length > 0
      ? {usedByUserId: privateData.usedByUserId}
      : {}),
    ...(typeof privateData.customerRecordId === 'string' &&
    privateData.customerRecordId.length > 0
      ? {customerRecordId: privateData.customerRecordId}
      : {}),
  };
}

async function main() {
  const snapshot = await db.collection('inviteCodes').get();
  const canonicalIds = new Set(snapshot.docs.map((document) => document.id));
  const operations = [];
  const skipped = [];

  for (const document of snapshot.docs) {
    const sourceData = document.data();
    const data = {...sourceData};
    const code = typeof data.code === 'string' ? data.code.trim().toUpperCase() : '';
    if (!codePattern.test(code)) {
      skipped.push(`${document.id}: invalid code`);
      continue;
    }
    if (!data.distributorId || !data.createdAt) {
      skipped.push(`${document.id}: missing required owner/timestamp fields`);
      continue;
    }
    if (!data.expiresAt && typeof data.createdAt.toMillis === 'function') {
      data.expiresAt = admin.firestore.Timestamp.fromMillis(
        data.createdAt.toMillis() + 7 * 24 * 60 * 60 * 1000,
      );
    }
    if (!data.expiresAt) {
      skipped.push(`${document.id}: expiresAt cannot be derived`);
      continue;
    }
    data.code = code;
    data.isUsed = data.isUsed === true;
    data.status = data.status ?? (data.isUsed ? 'used' : 'pending');
    if (data.status === 'pending' && data.expiresAt.toMillis() <= Date.now()) {
      data.status = 'expired';
    }
    if (data.status !== 'used') {
      data.isUsed = false;
      delete data.usedByUserId;
    } else if (typeof data.usedByUserId !== 'string' || data.usedByUserId.length === 0) {
      skipped.push(`${document.id}: used code has no usedByUserId`);
      continue;
    }
    if (document.id !== code && canonicalIds.has(code)) {
      skipped.push(`${document.id}: canonical document ${code} already exists`);
      continue;
    }

    let customerReference = null;
    if (
      document.id !== code &&
      typeof data.customerRecordId === 'string' &&
      data.customerRecordId.length > 0
    ) {
      customerReference = db
        .collection('users')
        .doc(data.distributorId)
        .collection('customers')
        .doc(data.customerRecordId);
      if (!(await customerReference.get()).exists) {
        skipped.push(`${document.id}: linked customer record does not exist`);
        continue;
      }
    }

    operations.push({document, data, code, customerReference});
  }

  console.log(
    `${shouldApply ? 'APPLY' : 'DRY-RUN'}: ${operations.length} invite codes ready, ` +
      `${skipped.length} skipped.`,
  );
  for (const reason of skipped) console.warn(`skip - ${reason}`);

  if (!shouldApply) {
    for (const operation of operations) {
      const action = operation.document.id === operation.code ? 'backfill' : 'normalize+backfill';
      console.log(`${action} - ${operation.document.id} -> ${operation.code}`);
    }
    console.log('No data changed. Re-run with --apply after reviewing this output.');
    return;
  }

  for (let offset = 0; offset < operations.length; offset += 100) {
    const batch = db.batch();
    for (const operation of operations.slice(offset, offset + 100)) {
      const {document, data, code, customerReference} = operation;
      const canonicalReference = db.collection('inviteCodes').doc(code);
      const lookupReference = db.collection('inviteCodeLookups').doc(code);

      batch.set(canonicalReference, {...data, code});
      batch.set(lookupReference, lookupData(data, code));

      if (document.id !== code) {
        if (customerReference) {
          batch.update(customerReference, {inviteCodeId: code});
        }
        batch.delete(document.ref);
      }
    }
    await batch.commit();
    console.log(`committed ${Math.min(offset + 100, operations.length)}/${operations.length}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
