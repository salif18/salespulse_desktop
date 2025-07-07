// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/client_model_pro.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/models/vente_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/client_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/services/vente_api.dart';

class AddVenteScreen extends StatefulWidget {
  const AddVenteScreen({super.key});

  @override
  State<AddVenteScreen> createState() => _AddVenteScreenState();
}

class _AddVenteScreenState extends State<AddVenteScreen> {
  ServicesStocks api = ServicesStocks();
  final ServicesClients _clientApi = ServicesClients();
  ServicesVentes venteApi = ServicesVentes();
  List<ProductModel> allProducts = [];
  List<ClientModel> allClients = [];

  List<ProductItemModel> panier = [];
  List<ProductModel> selectedProducts = [];
  ClientModel? selectedClient;

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _remiseGlobaleController =
      TextEditingController();
  String _remiseGlobaleType = 'fcfa';
  final TextEditingController _tvaGlobaleController = TextEditingController();
  final TextEditingController _livraisonController = TextEditingController();
  final TextEditingController _emballageController = TextEditingController();

  int total = 0;
  int monnaie = 0;
  String? selectedClientId;
  String selectedPaiement = 'cash';

  final List<String> modePaiementOptions = [
    'cash',
    'mobile money',
    'transfert bancaire',
    'crédit',
    'partiel'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadClients();
  }

  void _loadProducts() async {
    final produits = await fetchProduits();
    setState(() {
      allProducts = produits;
    });
  }

  Future<List<ProductModel>> fetchProduits() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      final res = await api.getAllProducts(token, userId);

      if (res.statusCode == 200) {
        final body = res.data;
        return (body["produits"] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();
      } else {
        debugPrint("Échec du chargement des produits : ${res.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement des produits: $e");
      return [];
    }
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _loadClients() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await _clientApi.getClients(userId, token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final clients = (body["clients"] as List)
              .map((json) => ClientModel.fromJson(json))
              .toList();
          allClients.addAll(clients);
        });
      }
    } catch (e) {
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

  void _ajouterAuPanier() async {
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Veuillez sélectionner au moins un produit",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var produit in selectedProducts) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _FormulaireProduitDialog(produit: produit),
      );

      if (result != null) {
        int qte = result["quantite"];
        int remise = result["remise"];
        String remiseType = result["remiseType"];
        int tva = result["tva"];
        int fraisLivraison = result["fraisLivraison"];
        int fraisEmballage = result["fraisEmballage"];

        // Calcul du prix final
        int prixInitial = produit.prixVente;
        int prixRemise = remiseType == 'pourcent'
            ? (prixInitial - (prixInitial * remise ~/ 100))
            : (prixInitial - remise);

        if (prixRemise < 0) prixRemise = 0;

        int sousTotalBase = prixInitial * qte;

        int sousTotalTva = (sousTotalBase + fraisLivraison + fraisEmballage);
        sousTotalTva += (tva > 0) ? (sousTotalBase * tva ~/ 100) : 0;

        final item = ProductItemModel(
          productId: produit.id,
          nom: produit.nom,
          image: produit.image,
          prixAchat: produit.prixAchat,
          prixUnitaire: prixInitial,
          quantite: qte,
          sousTotal: sousTotalTva,
          stocks: produit.stocks,
          remise: remise,
          remiseType: remiseType,
          tva: tva,
          fraisLivraison: fraisLivraison,
          fraisEmballage: fraisEmballage,
        );

        setState(() {
          panier.add(item);
          total = panier.fold(0, (sum, p) => sum + p.sousTotal);
        });
      }
    }

    selectedProducts.clear();
  }

  void _validerVente() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final operateur =
        Provider.of<AuthProvider>(context, listen: false).userName;
    int montantRecu = int.tryParse(_montantRecuController.text) ?? 0;
    monnaie = montantRecu > total ? (montantRecu - total) : 0;
    if (panier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Votre panier est vide",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            )),
      );
      return;
    }

    for (var item in panier) {
  if (item.stocks! < item.quantite) {
    showDialog(

      context: context,
      builder: (_) => AlertDialog(
        title: Text("Stock insuffisant", style: GoogleFonts.poppins(fontSize: 14,color:Colors.black),),
        content: Text("Le stock de ${item.nom} est insuffisant.",style: GoogleFonts.poppins(fontSize: 14,color:Colors.black)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK",style: GoogleFonts.poppins(fontSize: 14,color:Colors.black)))],
      ),
    );
    return;
  }
}
    // Calcul du reste (solde dû)
    int reste = total - montantRecu;
    if (reste < 0) reste = 0;

    // Déterminer le statut de la vente selon le montant reçu
    String statut;
    int livraison = int.tryParse(_livraisonController.text) ?? 0;
    int emballage = int.tryParse(_emballageController.text) ?? 0;
    if (montantRecu  >= (total + livraison + emballage)) {
      statut = "payée";
    } else if (montantRecu > 0 && montantRecu < (total + livraison + emballage)) {
      statut = "partiel";
    } else {
      statut = "crédit";
    }

    // AVERTISSEMENT : vente à crédit ou partielle sans client
if ((statut == "partiel" || statut == "crédit") && selectedClient == null) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Client requis", style: GoogleFonts.poppins(fontSize: 16)),
      content: Text(
        "Pour une vente à crédit ou un paiement partiel, vous devez sélectionner ou enregistrer le client.",
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("OK", style: GoogleFonts.poppins()),
        )
      ],
    ),
  );
  return;
}


    final venteMap = {
      "userId": userId,
      "clientId": selectedClient?.id,
      "nom": selectedClient?.nom ?? "Anonyme",
      "contactClient": selectedClient?.contact,
      "produits": panier.map((e) => e.toJson()).toList(),
      "total": total,
      "montant_recu": montantRecu,
      "remiseGlobale": int.tryParse(_remiseGlobaleController.text) ?? 0,
      "remiseGlobaleType": _remiseGlobaleType,
      "tvaGlobale": int.tryParse(_tvaGlobaleController.text) ?? 0,
      "livraison": int.tryParse(_livraisonController.text) ?? 0,
      "emballage": int.tryParse(_emballageController.text) ?? 0,
      "monnaie": monnaie,
      "reste": reste,
      "type_paiement": selectedPaiement,
      "statut": statut,
      "operateur": operateur,
      "date": DateTime.now().toIso8601String(),
    };

    final response = await venteApi.postOrders(venteMap, token);
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Vente enregistrée avec succès",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
            )),
      );
      setState(() {
        panier.clear();
        total = 0;
        _montantRecuController.clear();
        selectedClientId = null;
        selectedPaiement = 'cash';
        _remiseGlobaleController.clear();
        _remiseGlobaleType = 'fcfa';
        _tvaGlobaleController.clear();
        _livraisonController.clear();
        _emballageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thème local avec Poppins
    final theme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 16),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );

    return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(
              "Nouvelle vente",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: const Color(0xff001c30),
            elevation: 2,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==== Colonne Gauche (Sélection + Panier) ====
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sélection produit
                        GestureDetector(
                          onTap: _ouvrirModalSelectionProduit,
                          onLongPress: () {
                            if (selectedProducts.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Produits sélectionnés"),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: selectedProducts.length,
                                      itemBuilder: (context, index) {
                                        final produit = selectedProducts[index];
                                        return ListTile(
                                          leading: Image.network(
                                            produit.image ?? '',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.image_not_supported),
                                          ),
                                          title: Text(produit.nom),
                                          subtitle:
                                              Text("${produit.prixVente} Fcfa"),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Fermer"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedProducts.isNotEmpty
                                      ? Icons.check_circle
                                      : Icons.add_shopping_cart,
                                  color: selectedProducts.isNotEmpty
                                      ? Colors.green
                                      : Colors.blue.shade700,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedProducts.isNotEmpty
                                        ? "${selectedProducts.length} produit(s) sélectionné(s)"
                                        : "Choisir un ou plusieurs produits",
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down,
                                    color: Colors.blue.shade700),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quantité
                        TextField(
                          controller: _quantiteController,
                          decoration:
                             const InputDecoration(labelText: "Quantité"),
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        // Ajouter au panier
                        ElevatedButton.icon(
                          onPressed: _ajouterAuPanier,
                          label: const Text("Ajouter au panier"),
                          icon: const Icon(Icons.shopify_outlined, size: 28),
                        ),
                        const SizedBox(height: 16),
                        // Panier
                        Expanded(
                          child: ListView.builder(
                            itemCount: panier.length,
                            itemBuilder: (context, index) {
                              final item = panier[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.white,
                                shadowColor: Colors.grey[100],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Image.network(
                                        item.image ?? '',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.image_not_supported),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.nom,
                                                style:
                                                    theme.textTheme.bodyMedium),
                                            const SizedBox(height: 4),
                                            Text(
                                                "Unité: ${item.prixUnitaire} Fcfa",
                                                style:
                                                    theme.textTheme.bodySmall),
                                            const SizedBox(height: 4),
                                            Text(
                                                "Sous-total: ${item.sousTotal} Fcfa",
                                                style:
                                                    theme.textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                if (item.quantite > 1) {
                                                  item.quantite--;
                                                  item.sousTotal =
                                                      item.quantite *
                                                          item.prixUnitaire;
                                                } else {
                                                  panier.removeAt(index);
                                                }
                                                total = panier.fold(
                                                    0,
                                                    (sum, e) =>
                                                        sum + e.sousTotal);
                                              });
                                            },
                                          ),
                                          Text('${item.quantite}',
                                              style:
                                                  theme.textTheme.bodyMedium),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.green),
                                            onPressed: () {
                                              if (item.quantite >=
                                                  item.stocks!) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    content: Text(
                                                      "Stock insuffisant pour ${item.nom}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              setState(() {
                                                item.quantite++;
                                                item.sousTotal = item.quantite *
                                                    item.prixUnitaire;
                                                total = panier.fold(
                                                    0,
                                                    (sum, e) =>
                                                        sum + e.sousTotal);
                                              });
                                            },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),

                  // ==== Colonne Droite (Client + Paiement) ====
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total: $total Fcfa",
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _ouvrirModalSelectionClient,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedClient != null
                                        ? selectedClient!.nom
                                        : "Choisir un client (optionnel)",
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down,
                                    color: Colors.blue.shade700),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedPaiement,
                          decoration: const InputDecoration(
                              labelText: "Mode de paiement"),
                          items: modePaiementOptions
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedPaiement = val!),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _montantRecuController,
                          decoration:
                              const InputDecoration(labelText: "Montant reçu"),
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        // Remise globale
                        const SizedBox(height: 12),
                        TextField(
                          controller: _remiseGlobaleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Remise globale",
                            suffixText: 'Fcfa',
                          ),
                        ),
// Type de remise
                        DropdownButtonFormField<String>(
                          value: _remiseGlobaleType,
                          decoration:
                              const InputDecoration(labelText: "Type remise"),
                          items: ['fcfa', 'pourcent']
                              .map((v) =>
                                  DropdownMenuItem(value: v, child: Text(v)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _remiseGlobaleType = v!),
                        ),
// TVA globale
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tvaGlobaleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "TVA globale (%)"),
                        ),
// Frais livraison
                        const SizedBox(height: 12),
                        TextField(
                          controller: _livraisonController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Frais livraison (Fcfa)"),
                        ),
// Frais emballage
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emballageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: "Frais emballage (Fcfa)"),
                        ),
                        ElevatedButton.icon(
                          onPressed: _validerVente,
                          label: const Text("Valider la vente"),
                          icon: const Icon(Icons.check, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _ouvrirModalSelectionProduit() {
    List<ProductModel> produitsFiltres =
        List.from(allProducts); // Liste filtrée
    Set<ProductModel> produitsSelectionnes = {}; // Pour plusieurs sélections
    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher un produit...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          produitsFiltres = allProducts
                              .where((prod) => prod.nom
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),

                  const Divider(),

                  // Liste des produits avec cases à cocher
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: produitsFiltres.length,
                      itemBuilder: (context, index) {
                        final product = produitsFiltres[index];
                        final isSelected =
                            produitsSelectionnes.contains(product);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                produitsSelectionnes.add(product);
                              } else {
                                produitsSelectionnes.remove(product);
                              }
                            });
                          },
                          title: Text(product.nom,
                              style: GoogleFonts.poppins(fontSize: 14)),
                          subtitle: Text("${product.prixVente} Fcfa",
                              style: GoogleFonts.poppins(fontSize: 12)),
                          secondary: Image.network(
                            product.image ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),

                  const Divider(),

                  // Bouton Valider
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedProducts = produitsSelectionnes.toList();
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Valider la sélection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _ouvrirModalSelectionClient() {
    List<ClientModel> clientsFiltres = List.from(allClients);
    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Champ de recherche
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher un client...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          clientsFiltres = allClients
                              .where((client) => client.nom
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),

                  const Divider(),

                  // Liste des clients filtrés
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: clientsFiltres.length,
                      itemBuilder: (context, index) {
                        final client = clientsFiltres[index];
                        return ListTile(
                          leading: ClipOval(
                              child: Image.asset(
                            "assets/images/contact2.png",
                            width: 50,
                            height: 50,
                          )),
                          title: Text(client.nom, style: GoogleFonts.poppins()),
                          subtitle: Text(client.contact),
                          onTap: () {
                            setState(() {
                              selectedClient = client;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FormulaireProduitDialog extends StatefulWidget {
  final ProductModel produit;
  const _FormulaireProduitDialog({required this.produit});

  @override
  State<_FormulaireProduitDialog> createState() =>
      _FormulaireProduitDialogState();
}

class _FormulaireProduitDialogState extends State<_FormulaireProduitDialog> {
  final _qteCtrl = TextEditingController(text: "1");
  final _remiseCtrl = TextEditingController(text: "0");
  final _tvaCtrl = TextEditingController(text: "0");
  final _livraisonCtrl = TextEditingController(text: "0");
  final _emballageCtrl = TextEditingController(text: "0");
  String _remiseType = 'fcfa';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Détails pour ${widget.produit.nom}",),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                controller: _qteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantité")),
            TextField(
                controller: _remiseCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Remise")),
            DropdownButtonFormField<String>(
              value: _remiseType,
              items: ["fcfa", "pourcent"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _remiseType = val!),
              decoration: const InputDecoration(labelText: "Type de remise"),
            ),
            TextField(
                controller: _tvaCtrl,
                keyboardType: TextInputType.number,
                decoration:const InputDecoration(labelText: "TVA (%)")),
            TextField(
                controller: _livraisonCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Frais de livraison")),
            TextField(
                controller: _emballageCtrl,
                keyboardType: TextInputType.number,
                decoration:const InputDecoration(labelText: "Frais d'emballage")),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700
          ),
          onPressed: () {
            Navigator.pop(context, {
              "quantite": int.tryParse(_qteCtrl.text) ?? 1,
              "remise": int.tryParse(_remiseCtrl.text) ?? 0,
              "remiseType": _remiseType,
              "tva": int.tryParse(_tvaCtrl.text) ?? 0,
              "fraisLivraison": int.tryParse(_livraisonCtrl.text) ?? 0,
              "fraisEmballage": int.tryParse(_emballageCtrl.text) ?? 0,
            });
          },
          child: Text("Ajouter", style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        )
      ],
    );
  }
}
