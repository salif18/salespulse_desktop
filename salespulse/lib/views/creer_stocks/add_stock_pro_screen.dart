// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final ServicesStocks api = ServicesStocks();
  final ServicesCategories apiCatego = ServicesCategories();
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
  final TextEditingController _seuil = TextEditingController(text: '5');
  final TextEditingController _unite = TextEditingController(text: 'pièce');
  final TextEditingController _prixPromo = TextEditingController();
  String? _selectedCategorie;

  DateTime? _dateAchat;
  DateTime? _dateExpiration;
  bool _isPromo = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await apiCatego.getCategories(token);
      if (res.statusCode == 200) {
        setState(() {
          _categoriesList = (res.data["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      } else {
        throw Exception("Erreur ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur chargement catégories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement catégories: $e")),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      debugPrint("Erreur sélection image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la sélection de l'image")),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des dates
    if (_dateExpiration != null && _dateAchat != null && _dateExpiration!.isBefore(_dateAchat!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La date d'expiration doit être après la date d'achat")),
      );
      return;
    }

    // Validation des prix
    final prixAchat = double.tryParse(_prixAchat.text);
    final prixVente = double.tryParse(_prixVente.text);
    if (prixAchat == null || prixVente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer des prix valides")),
      );
      return;
    }

    if (prixVente < prixAchat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le prix de vente doit être supérieur au prix d'achat")),
      );
      return;
    }

    final formData = FormData();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    formData.fields
      ..add(MapEntry("adminId", adminId))
      ..add(MapEntry("nom", _nom.text))
      ..add(MapEntry("categories", _selectedCategorie!))
      ..add(MapEntry("description", _description.text))
      ..add(MapEntry("prix_achat", _prixAchat.text))
      ..add(MapEntry("prix_vente", _prixVente.text))
      ..add(MapEntry("stocks", _stock.text))
      ..add(MapEntry("seuil_alerte", _seuil.text))
      ..add(MapEntry("unite", _unite.text))
      ..add(MapEntry("isPromo", _isPromo.toString()))
      ..add(MapEntry("prix_promo", _prixPromo.text.isEmpty ? "0" : _prixPromo.text))
      ..add(MapEntry("date_achat", _dateAchat?.toIso8601String() ?? ""))
      ..add(MapEntry("date_expiration", _dateExpiration?.toIso8601String() ?? ""));

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produit ajouté avec succès")),
          );
        }
      } else {
        throw Exception("Erreur API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur soumission formulaire: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          "Ajouter un produit",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonne gauche - Image et import
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section image
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _imageUrl != null && _imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image_search,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Aucune image sélectionnée",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Boutons d'import
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: Text(
                                    "Galerie",
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _importFromExcel(context),
                                  icon: const Icon(Icons.insert_drive_file, size: 18),
                                  label: Text(
                                    "Importer Excel",
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _buildUrlImageDialog(),
                                    );
                                  },
                                  icon: const Icon(Icons.link, size: 18),
                                  label: Text(
                                    "Lien image",
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 32),
                      
                      // Colonne droite - Formulaire
                      Flexible(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ligne 1 - Nom et Catégorie
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    controller: _nom,
                                    label: "Nom du produit*",
                                    hint: "Saisissez le nom du produit",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _buildCategoryDropdown(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Description
                            _buildTextField(
                              controller: _description,
                              label: "Description",
                              hint: "Décrivez le produit...",
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            // Ligne 2 - Dates
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    context,
                                    label: "Date d'achat",
                                    date: _dateAchat,
                                    onDateSelected: (date) {
                                      setState(() => _dateAchat = date);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    context,
                                    label: "Date d'expiration",
                                    date: _dateExpiration,
                                    onDateSelected: (date) {
                                      setState(() => _dateExpiration = date);
                                    },
                                    isExpiration: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Ligne 3 - Prix
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _prixAchat,
                                    label: "Prix d'achat*",
                                    hint: "0.00",
                                    keyboardType: TextInputType.number,
                                    prefix: Text(
                                      "FCFA",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Ce champ est obligatoire";
                                      if (double.tryParse(value) == null) return "Valeur numérique invalide";
                                      if (double.parse(value) <= 0) return "Doit être supérieur à 0";
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _prixVente,
                                    label: "Prix de vente*",
                                    hint: "0.00",
                                    keyboardType: TextInputType.number,
                                    prefix: Text(
                                      "FCFA",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Ce champ est obligatoire";
                                      if (double.tryParse(value) == null) return "Valeur numérique invalide";
                                      if (double.parse(value) <= 0) return "Doit être supérieur à 0";
                                      if (_prixAchat.text.isNotEmpty && double.tryParse(_prixAchat.text) != null) {
                                        if (double.parse(value) <= double.parse(_prixAchat.text)) {
                                          return "Doit être supérieur au prix d'achat";
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Ligne 4 - Stock et Unité
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stock,
                                    label: "Stock initial*",
                                    hint: "0",
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return "Ce champ est obligatoire";
                                      if (int.tryParse(value) == null) return "Valeur numérique invalide";
                                      if (int.parse(value) < 0) return "Doit être positif";
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _unite,
                                    label: "Unité",
                                    hint: "pièce, kg, litre...",
                                    validator: (value) =>
                                        value!.isEmpty ? "Ce champ est obligatoire" : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Ligne 5 - Seuil d'alerte
                            _buildTextField(
                              controller: _seuil,
                              label: "Seuil d'alerte",
                              hint: "5",
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (int.tryParse(value) == null) return "Valeur numérique invalide";
                                  if (int.parse(value) < 0) return "Doit être positif";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Promotion
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isPromo ? Colors.orange[50] : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isPromo ? Colors.orange[100]! : Colors.grey[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      "Activer la promotion",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: _isPromo,
                                    onChanged: (value) {
                                      setState(() => _isPromo = value);
                                    },
                                  ),
                                  if (_isPromo) ...[
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _prixPromo,
                                      label: "Prix promotionnel*",
                                      hint: "0.00",
                                      keyboardType: TextInputType.number,
                                      prefix: Text(
                                        "FCFA",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      validator: _isPromo
                                          ? (value) {
                                              if (value == null || value.isEmpty) return "Ce champ est obligatoire";
                                              if (double.tryParse(value) == null) return "Valeur numérique invalide";
                                              if (double.parse(value) <= 0) return "Doit être supérieur à 0";
                                              if (_prixVente.text.isNotEmpty && double.tryParse(_prixVente.text) != null) {
                                                if (double.parse(value) >= double.parse(_prixVente.text)) {
                                                  return "Doit être inférieur au prix de vente";
                                                }
                                              }
                                              return null;
                                            }
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Bouton d'enregistrement
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0066CC),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "ENREGISTRER LE PRODUIT",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    bool isExpiration = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: isExpiration ? Colors.red[400]! : Colors.blue[400]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isExpiration ? Colors.red[400] : Colors.blue[400],
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : "Sélectionner une date",
                  style: GoogleFonts.poppins(
                    color: date != null ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            prefix: prefix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Catégorie*",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedCategorie,
          items: _categoriesList
              .map((cat) => DropdownMenuItem<String>(
                    value: cat.name,
                    child: Text(
                      cat.name,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedCategorie = value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          validator: (value) =>
              value == null ? "Veuillez sélectionner une catégorie" : null,
        ),
      ],
    );
  }

  Widget _buildUrlImageDialog() {
    return AlertDialog(
      title: Text(
        "Ajouter une image par URL",
        style: GoogleFonts.poppins(),
      ),
      content: TextField(
        decoration: InputDecoration(
          hintText: "https://example.com/image.jpg",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          _imageUrl = value;
          _imageFile = null;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Annuler", style: GoogleFonts.roboto(fontSize: 14, color: Colors.blueAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
          onPressed: () {
            if (_imageUrl != null && _imageUrl!.isNotEmpty) {
              setState(() {});
              Navigator.pop(context);
            }
          },
          child: Text("Valider", style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _importFromExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Importation en cours..."),
          ],
        ),
      ),
    );

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final filePath = result.files.single.path!;
      final fileBytes = File(filePath).readAsBytesSync();
      final decodedExcel = excel.Excel.decodeBytes(fileBytes);

      final firstSheetKey = decodedExcel.tables.keys.first;
      final sheet = decodedExcel.tables[firstSheetKey];
      if (sheet == null || sheet.rows.length < 2) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userId;

      int nbProduitsAjoutes = 0;
      List<String> erreurs = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        try {
          final row = sheet.rows[i];

          // ATTENTION : adapte les indices aux colonnes dans ton fichier Excel
          final photo = row.isNotEmpty ? row[0]?.value.toString().trim() ?? '' : '';
          final nom = row.length > 1 ? row[1]?.value.toString().trim() ?? '' : '';
          final categorie = row.length > 2 ? row[2]?.value.toString().trim() ?? '' : '';
          final description = row.length > 3 ? row[3]?.value.toString().trim() ?? '' : '';
          final prixAchat = row.length > 4 ? double.tryParse(row[4]?.value.toString() ?? '0') ?? 0 : 0;
          final prixVente = row.length > 5 ? double.tryParse(row[5]?.value.toString() ?? '0') ?? 0 : 0;
          final stock = row.length > 6 ? int.tryParse(row[6]?.value.toString() ?? '0') ?? 0 : 0;
          final seuil = row.length > 7 ? int.tryParse(row[7]?.value.toString() ?? '5') ?? 5 : 5;
          final unite = row.length > 8 ? row[8]?.value.toString().trim() ?? 'pièce' : 'pièce';
          final isPromoStr = row.length > 9 ? row[9]?.value.toString().toLowerCase() ?? 'false' : 'false';
          final prixPromo = row.length > 10 ? double.tryParse(row[10]?.value.toString() ?? '0') ?? 0 : 0;
          final dateAchatStr = row.length > 11 ? row[11]?.value.toString() ?? '' : '';
          final dateExpirationStr = row.length > 12 ? row[12]?.value.toString() ?? '' : '';

          if (nom.isEmpty || categorie.isEmpty) continue;

          bool isPromo = (isPromoStr == 'true' || isPromoStr == '1' || isPromoStr == 'oui');

          DateTime? dateAchat;
          DateTime? dateExpiration;

          try {
            if (dateAchatStr.isNotEmpty) dateAchat = DateTime.parse(dateAchatStr);
            if (dateExpirationStr.isNotEmpty) dateExpiration = DateTime.parse(dateExpirationStr);
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
            erreurs.add("Ligne ${i+1}: Erreur ${res.statusCode} - $nom");
          }
        } catch (e) {
          erreurs.add("Ligne ${i+1}: ${e.toString()}");
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (erreurs.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Erreurs d'import"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$nbProduitsAjoutes produit(s) importé(s) avec succès"),
                  const SizedBox(height: 16),
                  ...erreurs.take(5).map((e) => Text(e)),
                  if (erreurs.length > 5) const Text("... et d'autres erreurs"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$nbProduitsAjoutes produit(s) ajouté(s) depuis Excel."),
            backgroundColor: nbProduitsAjoutes > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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