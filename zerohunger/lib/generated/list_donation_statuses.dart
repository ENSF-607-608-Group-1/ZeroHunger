part of 'zerohunger.dart';

class ListDonationStatusesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListDonationStatusesVariablesBuilder(this._dataConnect, );
  Deserializer<ListDonationStatusesData> dataDeserializer = (dynamic json)  => ListDonationStatusesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListDonationStatusesData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListDonationStatusesData, void> ref() {
    
    return _dataConnect.query("ListDonationStatuses", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListDonationStatusesDonationStatuses {
  final BigInt statusId;
  final String name;
  ListDonationStatusesDonationStatuses.fromJson(dynamic json):
  
  statusId = bigIntFromJson(json['statusId']),
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationStatusesDonationStatuses otherTyped = other as ListDonationStatusesDonationStatuses;
    return statusId == otherTyped.statusId && 
    name == otherTyped.name;
    
  }
  @override
  int get hashCode => Object.hashAll([statusId.hashCode, name.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['statusId'] = bigIntToJson(statusId);
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListDonationStatusesDonationStatuses({
    required this.statusId,
    required this.name,
  });
}

@immutable
class ListDonationStatusesData {
  final List<ListDonationStatusesDonationStatuses> donationStatuses;
  ListDonationStatusesData.fromJson(dynamic json):
  
  donationStatuses = (json['donationStatuses'] as List<dynamic>)
        .map((e) => ListDonationStatusesDonationStatuses.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListDonationStatusesData otherTyped = other as ListDonationStatusesData;
    return donationStatuses == otherTyped.donationStatuses;
    
  }
  @override
  int get hashCode => donationStatuses.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donationStatuses'] = donationStatuses.map((e) => e.toJson()).toList();
    return json;
  }

  ListDonationStatusesData({
    required this.donationStatuses,
  });
}

