// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transferPageParams.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferPageParams _$TransferPageParamsFromJson(Map<String, dynamic> json) {
  return TransferPageParams()
    ..tokenNameId = json['tokenNameId'] as String?
    ..address = json['address'] as String?
    ..chainFrom = json['chainFrom'] as String?
    ..chainTo = json['chainTo'] as String?;
}

Map<String, dynamic> _$TransferPageParamsToJson(TransferPageParams instance) =>
    <String, dynamic>{
      'tokenNameId': instance.tokenNameId,
      'address': instance.address,
      'chainFrom': instance.chainFrom,
      'chainTo': instance.chainTo,
    };
