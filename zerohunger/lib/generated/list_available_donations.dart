part of 'zerohunger.dart';

class ListAvailableDonationsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAvailableDonationsVariablesBuilder(this._dataConnect, );
  Deserializer<ListAvailableDonationsData> dataDeserializer = (dynamic json)  => ListAvailableDonationsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAvailableDonationsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListAvailableDonationsData, void> ref() {
    
    return _dataConnect.query("ListAvailableDonations", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAvailableDonationsDonations {
  final String donationId;
  final String donationTitle;
  final String pickupTime;
  final BigInt itemQuantities;
  ListAvailableDonationsDonations.fromJson(dynamic json):
  
  donationId = nativeFromJson<String>(json['donationId']),
  donationTitle = nativeFromJson<String>(json['donationTitle']),
  pickupTime = nativeFromJson<String>(json['pickupTime']),
  itemQuantities = bigIntFromJson(json['itemQuantities']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAvailableDonationsDonations otherTyped = other as ListAvailableDonationsDonations;
    return donationId == otherTyped.donationId && 
    donationTitle == otherTyped.donationTitle && 
    pickupTime == otherTyped.pickupTime && 
    itemQuantities == otherTyped.itemQuantities;
    
  }
  @override
  int get hashCode => Object.hashAll([donationId.hashCode, donationTitle.hashCode, pickupTime.hashCode, itemQuantities.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donationId'] = nativeToJson<String>(donationId);
    json['donationTitle'] = nativeToJson<String>(donationTitle);
    json['pickupTime'] = nativeToJson<String>(pickupTime);
    json['itemQuantities'] = bigIntToJson(itemQuantities);
    return json;
  }

  ListAvailableDonationsDonations({
    required this.donationId,
    required this.donationTitle,
    required this.pickupTime,
    required this.itemQuantities,
  });
}

@immutable
class ListAvailableDonationsData {
  final List<ListAvailableDonationsDonations> donations;
  ListAvailableDonationsData.fromJson(dynamic json):
  
  donations = (json['donations'] as List<dynamic>)
        .map((e) => ListAvailableDonationsDonations.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAvailableDonationsData otherTyped = other as ListAvailableDonationsData;
    return donations == otherTyped.donations;
    
  }
  @override
  int get hashCode => donations.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['donations'] = donations.map((e) => e.toJson()).toList();
    return json;
  }

  ListAvailableDonationsData({
    required this.donations,
  });
}

