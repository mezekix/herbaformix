import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herbaformix/models/invite_status.dart';
import 'package:herbaformix/services/repositories/invite_code_repository.dart';

void main() {
  test('createInviteCode writes through its typed Firestore converter', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = InviteCodeRepository(firestore: firestore);

    final invite = await repository.createInviteCode('distributor-uid');

    expect(invite.code, hasLength(8));
    expect(invite.distributorId, 'distributor-uid');
    expect(invite.status, InviteStatus.pending);
    expect(invite.isUsed, isFalse);

    final privateSnapshot =
        await firestore.collection('inviteCodes').doc(invite.id).get();
    final lookupSnapshot =
        await firestore.collection('inviteCodeLookups').doc(invite.id).get();

    expect(privateSnapshot.data()?['code'], invite.code);
    expect(lookupSnapshot.data()?['code'], invite.code);
  });
}
