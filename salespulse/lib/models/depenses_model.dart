class DepensesModel {
  String id;
  String userId;
  int montants;
  String motifs;
  DateTime date;

  DepensesModel(
      {
      required this.id,
      required this.userId,
      required this.montants,
      required this.motifs,
      required this.date
      });

  factory DepensesModel.fromJson(Map<String, dynamic> json) {
    return DepensesModel(
        id: json["_id"],
        userId: json["userId"],
        montants: json["montants"],
        motifs: json["motifs"],
        date: DateTime.parse(json["createdAt"]));
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "montants": montants,
      "motifs": motifs,
      "createdAt": date.toIso8601String()
    };
  }
}
