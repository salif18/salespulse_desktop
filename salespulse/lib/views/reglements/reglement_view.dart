// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/reglement_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/reglement_api.dart';

class HistoriqueReglementsScreen extends StatefulWidget {
  const HistoriqueReglementsScreen({super.key});

  @override
  State<HistoriqueReglementsScreen> createState() => _HistoriqueReglementsScreenState();
}

class _HistoriqueReglementsScreenState extends State<HistoriqueReglementsScreen> {
  List<ReglementModel> reglements = [];

  @override
  void initState() {
    super.initState();
    _fetchReglements();
  }

  Future<void> _fetchReglements() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
   try{
     final response = await ServicesReglements().getReglements(token);
    if (response.statusCode == 200) {
      setState(() {
        reglements = (response.data["reglements"] as List)
            .map((json) => ReglementModel.fromJson(json))
            .toList();
      });
    }
   }on DioException {
       ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text( "Problème de connexion : Vérifiez votre Internet.", style: GoogleFonts.poppins(fontSize: 14),)));

  } on TimeoutException {
     ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(  "Le serveur ne répond pas. Veuillez réessayer plus tard.",style: GoogleFonts.poppins(fontSize: 14),)));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    debugPrint(e.toString());
  }
   
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Historique des règlements",
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
        backgroundColor: Colors.white//const Color(0xff001c30),
      ),
      body: reglements.isEmpty
    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Image.asset("assets/images/not_data.png",width: 200,height: 200, fit: BoxFit.cover),
                                  const SizedBox(height: 20),
                          Text("Aucun produit trouvé",
                              style: GoogleFonts.poppins(fontSize: 14)),
                        ],
                      ))
    : SingleChildScrollView(
      child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Container(
                  color: Colors.white,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 35,
                    headingRowColor: WidgetStateProperty.all(Colors.orange.shade700),
                    headingTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    columns: [
                      DataColumn(label: Expanded(child: Text("Nom".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black)))),
                      DataColumn(label: Text("Montant".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black))),
                      DataColumn(label: Text("Type".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black))),
                      DataColumn(label: Text("Mode".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black))),
                      DataColumn(label: Text("Date".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black))),
                      DataColumn(label: Text("Opérateur".toUpperCase(), style: GoogleFonts.roboto(fontSize: 13, color: Colors.black))),
                    ],
                    rows: reglements.map((r) {
                      return DataRow(cells: [
                        DataCell(Text(r.nom , style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                        DataCell(Text("${r.montant} Fcfa" , style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                        DataCell(Text(r.type, style: TextStyle( color: r.type == "règlement" ? Colors.green : Colors.red, fontWeight: FontWeight.bold),)),
                        DataCell(Text(r.mode  , style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                        DataCell(Text(DateFormat('dd/MM/yyyy').format(r.date) , style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                        DataCell(Text(r.operateur , style: GoogleFonts.poppins(fontSize: 14, color: Colors.black))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
    )

    );
  }
}
