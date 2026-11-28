import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';

void main() {
  test('persistence exception includes Data Connect operation errors', () {
    final cause = DataConnectOperationError<Map<String, dynamic>>(
      DataConnectErrorCode.other,
      'Failed to invoke operation: ',
      DataConnectOperationFailureResponse<Map<String, dynamic>>(
        [
          DataConnectOperationFailureResponseErrorInfo([
            DataConnectFieldPathSegment('donation_insert'),
          ], 'foreign key constraint failed'),
        ],
        {},
        null,
      ),
    );

    final exception = DonationPersistenceException('donation-id', cause);

    expect(
      exception.toString(),
      contains('donation_insert: foreign key constraint failed'),
    );
  });
}
