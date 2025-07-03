class CreditModel {
  final String id;
  final String userId;
  final String nom;
  final String contact;
  final int creditTotal;
  final int montantPaye;
  final int reste;
  final int monnaie;
  final String recommandation;
  final String statut;
  final DateTime date;

  CreditModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.contact,
    required this.creditTotal,
    required this.montantPaye,
    required this.reste,
    required this.monnaie,
    required this.recommandation,
    required this.statut,
    required this.date,
  });


   factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id:json["_id"],
      userId:json["userId"],
      nom: json['nom'],
      contact: json['contact'],
      creditTotal: json['credit_total'],
      montantPaye: json['montant_paye'],
      reste:json["reste"],
      monnaie:json["monnaie"],
      recommandation: json['recommandation'],
      statut: json["statut"],
      date:  DateTime.parse(json["date"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id":id,
      "userId":userId,
      "nom": nom,
      "contact": contact,
      "credit_total": creditTotal,
      "montant_paye": montantPaye,
      "reste": reste,
      "monnaie":monnaie,
      "recommandation":recommandation,
      "statut":statut,
      "date": date.toIso8601String(),  
    };
  }
}
