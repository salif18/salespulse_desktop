// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/services/stocks_api.dart';

class AddProduitPage extends StatefulWidget {
  const AddProduitPage({super.key});

  @override
  State<AddProduitPage> createState() => _AddProduitPageState();
}

class _AddProduitPageState extends State<AddProduitPage> {
  ServicesStocks api = ServicesStocks();
    ServicesCategories apiCatego = ServicesCategories();
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  List<CategoriesModel> _categoriesList = [];

  File? _imageFile;
  String? _imageUrl;

  final TextEditingController _nom = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _prixAchat = TextEditingController();
  final TextEditingController _prixVente = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _seuil = TextEditingController();
  final TextEditingController _unite = TextEditingController(text: 'pièce');
  final TextEditingController _prixPromo = TextEditingController();
  String? _selectedCategorie;

  DateTime? _dateAchat;
  DateTime? _dateExpiration;
  bool _isPromo = false;


  @override
  void initState() {
    super.initState();
    // Charger les produits au démarrage
    _loadCategories();
  }


  Future<void> _pickImageFromGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = FormData();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    formData.fields
      ..add(MapEntry("userId", userId))
      ..add(MapEntry("nom", _nom.text))
      ..add(MapEntry("categories", _selectedCategorie!))
      ..add(MapEntry("description", _description.text))
      ..add(MapEntry("prix_achat", _prixAchat.text))
      ..add(MapEntry("prix_vente", _prixVente.text))
      ..add(MapEntry("stocks", _stock.text))
      ..add(MapEntry("seuil_alerte", _seuil.text.isEmpty ? "5" : _seuil.text))
      ..add(MapEntry("unite", _unite.text))
      ..add(MapEntry("isPromo", _isPromo.toString()))
      ..add(MapEntry(
          "prix_promo", _prixPromo.text.isEmpty ? "0" : _prixPromo.text))
      ..add(MapEntry("date_achat", _dateAchat?.toIso8601String() ?? ""))
      ..add(MapEntry(
          "date_expiration", _dateExpiration?.toIso8601String() ?? ""));

    if (_imageFile != null) {
      final fileName = _imageFile!.path.split('/').last;
      formData.files.add(MapEntry(
        "image",
        await MultipartFile.fromFile(_imageFile!.path, filename: fileName),
      ));
    } else if (_imageUrl != null) {
      formData.fields.add(MapEntry("image", _imageUrl!));
    }

    try {
      final response = await api.postNewProduct(formData, token);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produit ajouté avec succès")),
        );
        
      } else {
        throw Exception("Erreur API");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _loadCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    try {
      final res = await apiCatego.getCategories(userId, token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          _categoriesList = (body["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xff001c30),
        title: Text(
          "Ajouter un produit",
          style: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== Colonne Gauche : Import & Image ====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _importFromExcel(context),
                      icon: const Icon(Icons.backup, color: Colors.white),
                      label: Text("Importer depuis Excel",
                          style: GoogleFonts.montserrat(
                              fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        maximumSize: const Size(280, 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon:
                          const Icon(Icons.image_rounded, color: Colors.white),
                      label: Text("Choisir une image",
                          style: GoogleFonts.montserrat(
                              fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(250, 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Ou coller un lien d'image",
                        style: GoogleFonts.roboto(
                            fontSize: 14, color: Colors.black)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: "https://image.example.com",
                          filled: true,
                          fillColor: Colors.grey[50],
                          labelStyle: GoogleFonts.roboto(
                              fontSize: 14, color: Colors.black),
                          border: const OutlineInputBorder(
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (value) {
                          _imageUrl = value;
                          _imageFile = null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_imageFile != null ||
                        (_imageUrl != null && _imageUrl!.isNotEmpty))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imageFile != null
                            ? Image.file(_imageFile!,
                                width: 200, height: 120, fit: BoxFit.cover)
                            : Image.network(_imageUrl!,
                                width: 200, height: 120, fit: BoxFit.cover),
                      ),
                  ],
                ),

                const SizedBox(width: 24),

                // ==== Colonne Droite : Champs ====
                Expanded(
                  child: Column(
                    children: [
                      _buildField(_nom, "Nom du produit"),
                    Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: SizedBox(
    width: 800,
    child: DropdownButtonFormField<String>(
      value: _selectedCategorie,
      items: _categoriesList
          .map((cat) => DropdownMenuItem<String>(
                value: cat.name, // Use the id or another unique string property
                child: Text(cat.name, style: GoogleFonts.roboto(fontSize: 14)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedCategorie = value);
      },
      decoration: InputDecoration(
        labelText: "Catégorie",
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
        border: const OutlineInputBorder(borderSide: BorderSide.none),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "Veuillez sélectionner une catégorie" : null,
    ),
  ),
),

                      _buildField(_description, "Description", maxLines: 3),
                      _buildField(_prixAchat, "Prix d'achat",
                          keyboardType: TextInputType.number),
                      _buildField(_prixVente, "Prix de vente",
                          keyboardType: TextInputType.number),
                      _buildField(_stock, "Stocks disponibles",
                          keyboardType: TextInputType.number),
                      _buildField(_seuil, "Seuil d'alerte (facultatif)",
                          keyboardType: TextInputType.number),
                      _buildField(_unite, "Unité"),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: 800,
                        child: SwitchListTile(
                          value: _isPromo,
                          onChanged: (val) => setState(() => _isPromo = val),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Produit en promotion ?",
                                  style: GoogleFonts.roboto(fontSize: 14)),
                              if (_isPromo)
                                Expanded(
                                  child: _buildField(
                                      _prixPromo, "Prix promotionnel",
                                      keyboardType: TextInputType.number),
                                ),
                            ],
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Dates
                      SizedBox(
                        width: 800,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  _dateAchat == null
                                      ? "Date achat"
                                      : DateFormat("dd MMM yyyy")
                                          .format(_dateAchat!),
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setState(() => _dateAchat = picked);
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  _dateExpiration == null
                                      ? "Date expiration"
                                      : DateFormat("dd MMM yyyy")
                                          .format(_dateExpiration!),
                                ),
                                trailing: const Icon(Icons.calendar_today,
                                    color: Colors.red),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setState(() => _dateExpiration = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text("Enregistrer",
                            style: GoogleFonts.roboto(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          minimumSize: const Size.fromHeight(45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: 800,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.grey[50],
            labelStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
            border: const OutlineInputBorder(borderSide: BorderSide.none),
          ),
          validator: (v) => v!.isEmpty ? "Champ requis" : null,
        ),
      ),
    );
  }

  void _importFromExcel(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return; // Annulé

      final filePath = result.files.single.path!;
      final fileBytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(fileBytes);

      final firstSheetKey = excel.tables.keys.first;
      final sheet = excel.tables[firstSheetKey];
      if (sheet == null || sheet.rows.length < 2) return;

      int nbProduitsAjoutes = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // ATTENTION : adapte les indices aux colonnes dans ton fichier Excel
        final photo =
            row.isNotEmpty ? row[0]?.value.toString().trim() ?? '' : '';
        final nom = row.length > 1 ? row[1]?.value.toString().trim() ?? '' : '';
        final categorie =
            row.length > 2 ? row[2]?.value.toString().trim() ?? '' : '';
        final description =
            row.length > 3 ? row[3]?.value.toString().trim() ?? '' : '';
        final prixAchat = row.length > 4
            ? double.tryParse(row[4]?.value.toString() ?? '0') ?? 0
            : 0;
        final prixVente = row.length > 5
            ? double.tryParse(row[5]?.value.toString() ?? '0') ?? 0
            : 0;
        final stock = row.length > 6
            ? int.tryParse(row[6]?.value.toString() ?? '0') ?? 0
            : 0;
        final seuil = row.length > 7
            ? int.tryParse(row[7]?.value.toString() ?? '5') ?? 5
            : 5;
        final unite = row.length > 8
            ? row[8]?.value.toString().trim() ?? 'pièce'
            : 'pièce';
        final isPromoStr = row.length > 9
            ? row[9]?.value.toString().toLowerCase() ?? 'false'
            : 'false';
        final prixPromo = row.length > 10
            ? double.tryParse(row[10]?.value.toString() ?? '0') ?? 0
            : 0;
        final dateAchatStr =
            row.length > 11 ? row[11]?.value.toString() ?? '' : '';
        final dateExpirationStr =
            row.length > 12 ? row[12]?.value.toString() ?? '' : '';

        if (nom.isEmpty || categorie.isEmpty) continue;

        bool isPromo =
            (isPromoStr == 'true' || isPromoStr == '1' || isPromoStr == 'oui');

        DateTime? dateAchat;
        DateTime? dateExpiration;

        try {
          if (dateAchatStr.isNotEmpty) dateAchat = DateTime.parse(dateAchatStr);
          if (dateExpirationStr.isNotEmpty) {
            dateExpiration = DateTime.parse(dateExpirationStr);
          }
        } catch (_) {
          // Ignorer erreurs de parsing date
        }

        final data = {
          "userId": userId,
          "nom": nom,
          "image": photo,
          "categories": categorie,
          "description": description,
          "prix_achat": prixAchat.toString(),
          "prix_vente": prixVente.toString(),
          "stocks": stock.toString(),
          "seuil_alerte": seuil.toString(),
          "unite": unite,
          "isPromo": isPromo.toString(),
          "prix_promo": prixPromo.toString(),
          "date_achat": dateAchat?.toIso8601String() ?? "",
          "date_expiration": dateExpiration?.toIso8601String() ?? "",
        };

        final res = await api.postNewProduct(data, token);

        if (res.statusCode == 201 || res.statusCode == 200) {
          nbProduitsAjoutes++;
        } else {
          debugPrint("Erreur ajout produit '$nom': status ${res.statusCode}");
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("$nbProduitsAjoutes produit(s) ajouté(s) depuis Excel."),
          backgroundColor: nbProduitsAjoutes > 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint("Erreur import Excel : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'importation du fichier Excel"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
