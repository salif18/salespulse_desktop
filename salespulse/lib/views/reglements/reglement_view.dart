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
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;

    final response = await ServicesReglements().getReglements(userId, token);
    if (response.statusCode == 200) {
      setState(() {
        reglements = (response.data["reglements"] as List)
            .map((json) => ReglementModel.fromJson(json))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Historique des règlements",
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xff001c30),
      ),
      body: reglements.isEmpty
    ? const Center(child: CircularProgressIndicator())
    : LayoutBuilder(
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
                      DataCell(Text(
                        r.type,
                        style: TextStyle(
                            color: r.type == "règlement"
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold),
                      )),
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
      )

    );
  }
}
