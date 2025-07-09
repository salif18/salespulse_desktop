// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RecuVenteScreen extends StatelessWidget {
  final Map data;

  const RecuVenteScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final produits = List<Map<String, dynamic>>.from(data["produits"]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff001c30),
        title: Text("Reçu de Vente",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Impression
              generateInvoicePdf(
                numero: data['numero']?.toString() ?? 'N/A',
                typeDoc: 'Reçu',
                clientNom: data['nom'] ?? '-',
                clientContact: data['contactClient'] ?? '-',
                vendeur: data['operateur'] ?? '-',
                statut: data['statut'] ?? '-',
                date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
                produits:
                    List<Map<String, dynamic>>.from(data["produits"] ?? []),
                total: data['total'] ?? 0,
                montantRecu: data['montant_recu'] ?? 0,
                monnaie: data['monnaie'] ?? 0,
                reste: data['reste'] ?? 0,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Informations Client et Vente"),
                  const SizedBox(height: 8),
                  _info("👤 Client", data['nom']),
                  if (data["contactClient"] != null)
                    _info("📞 Contact", data['contactClient']),
                  _info("🧑‍💼 Vendeur", data['operateur']),
                  _info("📅 Date", _formatDate(data["date"])),
                  _info("🧾 Statut", data['statut']),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 16),
                  _sectionTitle("🛒 Détails des produits"),
                  const SizedBox(height: 8),
                  ...produits.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "${item['nom'] ?? '-'} x${item['quantite'] ?? 0}",
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                  "Prix unitaire : ${item['prixUnitaire'] ?? 0} Fcfa",
                                  style: _detailStyle()),
                              Text(
                                  "Remise : ${item['remise'] ?? 0} ${item['remiseType'] == 'pourcent' ? '%' : 'Fcfa'}",
                                  style: _detailStyle()),
                              Text("TVA : ${item['tva'] ?? 0}%",
                                  style: _detailStyle()),
                              Text(
                                  "Sous-total : ${item['sousTotal'] ?? 0} Fcfa",
                                  style: _detailStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 16),
                  _sectionTitle("🧾 Récapitulatif"),
                  const SizedBox(height: 8),
                  _info("Sous-total brut",
                      "${_calculeSousTotalBrut(produits)} Fcfa"),
                  _info("Remise globale",
                      "${data['remiseGlobale'] ?? 0} ${data['remiseGlobaleType'] == 'pourcent' ? '%' : 'Fcfa'}"),
                  _info("TVA globale", "${data['tvaGlobale'] ?? 0}%"),
                  _info("Frais de livraison", "${data['livraison'] ?? 0} Fcfa"),
                  _info("Frais d'emballage", "${data['emballage'] ?? 0} Fcfa"),
                  const Divider(),
                  _info("💰 Total à payer", "${data['total'] ?? 0} Fcfa",
                      bold: true, color: Colors.blueAccent),
                  _info("💵 Montant reçu", "${data['montant_recu'] ?? 0} Fcfa"),
                  _info("💸 Monnaie rendue", "${data['monnaie'] ?? 0} Fcfa"),
                  if ((data["reste"] ?? 0) > 0)
                    _info("❗ Reste à payer", "${data['reste'] ?? 0} Fcfa",
                        bold: true, color: Colors.redAccent),
                  _info("Mode de paiement", data['type_paiement'] ?? '-'),
                  const SizedBox(height: 16),
                  Center(
                    child: Text("Merci pour votre achat !",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _info(String label, dynamic value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value?.toString() ?? '-',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  TextStyle _detailStyle({FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.poppins(
        fontSize: 13, fontWeight: fontWeight, color: Colors.black87);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  int _calculeSousTotalBrut(List<Map<String, dynamic>> produits) {
    int total = 0;
    for (var item in produits) {
      total += (item['sousTotal'] ?? 0) as int;
    }
    return total;
  }

  Future<void> generateInvoicePdf({
    required String numero,
    required String typeDoc,
    required String clientNom,
    required String clientContact,
    required String vendeur,
    required String statut,
    required DateTime date,
    required List<Map<String, dynamic>> produits,
    required int total,
    required int montantRecu,
    required int reste,
    required int monnaie,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nom de ta boutique',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.Text(typeDoc,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        )),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text("N° : $numero"),
                pw.SizedBox(height: 16),
                pw.Text("Client : $clientNom"),
                pw.Text("Contact : $clientContact"),
                pw.SizedBox(height: 8),
                pw.Text("Vendeur : $vendeur"),
                pw.Text("Date : ${date.toLocal().toString().substring(0, 16)}"),
                pw.Text("Statut : $statut"),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Table.fromTextArray(
                  border: null,
                  headers: ['Produit', 'Qté', 'Prix', 'Total'],
                  data: produits.map((e) {
                    return [
                      e['nom'] ?? '-',
                      '${e['quantite'] ?? 0}',
                      '${e['prix'] ?? 0} F',
                      '${e['total'] ?? 0} F',
                    ];
                  }).toList(),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey800),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Total : $total F",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Montant reçu : $montantRecu F"),
                        pw.Text("Monnaie rendue : $monnaie F"),
                        pw.Text("Reste à payer : $reste F"),
                      ],
                    )
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Center(
                    child: pw.Text("Merci pour votre achat !",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        )))
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
