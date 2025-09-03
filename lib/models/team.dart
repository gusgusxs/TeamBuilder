// lib/models/team.dart
class TeamModel {
  final String id;
  String name;
  List<int> memberIds;

  TeamModel({
    required this.id,
    required this.name,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
      };

  factory TeamModel.fromJson(Map<String, dynamic> j) => TeamModel(
        id: j['id'] as String,
        name: j['name'] as String,
        memberIds: (j['memberIds'] as List).cast<int>(),
      );
}
