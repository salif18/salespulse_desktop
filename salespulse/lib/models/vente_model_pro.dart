// Model future pour mode pro

class ProductItemModel {
  final String productId;
  final String nom;
  final String? image;
  final int prixUnitaire;
  int quantite;
  int sousTotal;
  int? stocks; // ✅ stock disponible

  ProductItemModel({
    required this.productId,
    required this.nom,
    required this.image,
    required this.prixUnitaire,
    required this.quantite,
    required this.sousTotal,
    required this.stocks
  });

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
      productId: json['productId'] ?? "",
      nom: json['nom'] ?? "",
      image:json["image"]?? "",
      prixUnitaire: json['prix_unitaire'] ?? "",
      quantite: json['quantite'] ?? "",
      sousTotal: json['sous_total'] ?? "",
      stocks: json["stocks"] ?? 0
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'nom': nom,
      'image':image,
      'prix_unitaire': prixUnitaire,
      'quantite': quantite,
      'sous_total': sousTotal,
      'stocks':stocks
    };
  }
}


class VenteModel {
  final String id;
  final String userId;
  final String? clientId;
  final String? clientNom;
  final List<ProductItemModel> produits;
  final int total;
  final int montantRecu;
  final int monnaie;
  final int reste;
  final String typePaiement;
  final String statut;
  final DateTime date;

  VenteModel({
    required this.id,
    required this.userId,
    this.clientId,
    this.clientNom,
    required this.produits,
    required this.total,
    required this.montantRecu,
    required this.monnaie,
    required this.reste,
    required this.typePaiement,
    required this.statut,
    required this.date,
  });

  factory VenteModel.fromJson(Map<String, dynamic> json) {
    return VenteModel(
      id: json['_id'] ?? "",
      userId: json['userId']  ?? "",
      clientId: json['clientId'] ?? "",
      // ignore: unnecessary_type_check
      clientNom: json['nom'],
      produits: (json['produits'] as List)
          .map((item) => ProductItemModel.fromJson(item))
          .toList(),
      total: json['total'] ?? "",
      montantRecu: json['montant_recu'] ?? "",
      monnaie: json['monnaie'] ?? "",
      reste:json["reste"] ?? "",
      typePaiement: json['type_paiement'] ?? "",
      statut: json['statut'],
      date: DateTime.parse(json['date'] ?? ""),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'clientId': clientId,
      'nom':clientNom,
      'produits': produits.map((p) => p.toJson()).toList(),
      'total': total,
      'montant_recu': montantRecu,
      'monnaie': monnaie,
      'reste':reste,
      'type_paiement': typePaiement,
      'statut': statut,
      'date': date.toIso8601String(),
    };
  }
}

