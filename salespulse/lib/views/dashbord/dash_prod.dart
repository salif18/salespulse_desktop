// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/utils/format_prix.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  final ServicesStats api = ServicesStats();
  final FormatPrice _formatPrice = FormatPrice();

  int totalVentes = 0;
  int montantEncaisse = 0;
  int resteTotal = 0;
  int montantRembourse = 0;
  int nombreVentes = 0;
  int nombreClients = 0;
  int produitsEnStock = 0;
  int totalPiecesEnStock = 0;
  int produitsRupture = 0;
  int totalDepenses = 0;
  int etatCaisse = 0;
  int coutAchatTotal = 0;
  int coutAchatPertes = 0; // Produits retirés/volés       // Produits en stock
  int quantitePertes = 0;
  int benefice = 0;
  int totalRemises = 0;
  int totalTVACollectee = 0;

  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Map<String, dynamic>> moisFiltres = [];
  List<Map<String, dynamic>> ventesDuJour = [];
  List<Map<String, dynamic>> ventesAnnee = [];
  Map<String, dynamic> statsParMois = {};
  List<Map<String, dynamic>> ventesHebdo = [];

  @override
  void initState() {
    super.initState();
    _generateMonthFilters();
    _fetchStats();
    _fetchStatsCharts();
  }

  void _generateMonthFilters() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      moisFiltres.add({
        "label": DateFormat("MMMM yyyy", "fr_FR").format(date),
        "value": DateFormat("yyyy-MM").format(date),
      });
    }
  }

  Future<void> _fetchStats() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await api.getStatsGenerales(selectedMonth, token);
    if (res.statusCode == 200) {
      final data = res.data;
      setState(() {
        totalVentes = data['totalVentesBrutes'] ?? 0;
        montantEncaisse = data['montantEncaisse'] ?? 0;
        resteTotal = data['resteTotal'] ?? 0;
        montantRembourse = data["montantRembourse"] ?? 0;
        nombreVentes = data['nombreVentes'] ?? 0;
        nombreClients = data['nombreClients'] ?? 0;
        produitsEnStock = data['produitsEnStock'] ?? 0;
        totalPiecesEnStock = data["totalPiecesEnStock"] ?? "";
        produitsRupture = data['produitsRupture'] ?? 0;
        totalDepenses = data['totalDepenses'] ?? 0;
        coutAchatTotal = data['coutAchatTotal'] ?? 0;
        etatCaisse = data["etatCaisse"] ?? 0;
        benefice = data['benefice'] ?? 0;
        coutAchatPertes = data["coutAchatPertes"] ?? 0;
        quantitePertes = data["quantitePertes"] ?? 0;
        totalRemises = data["totalRemises"] ?? 0;
        totalTVACollectee = data["totalTVACollectee"] ?? 0;
        statsParMois = data['statsParMois'] ?? {};
      });
    }
  }

  Future<void> _fetchStatsCharts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final resJour = await api.getVentesDuJour(token);
      final resAnnee = await api.getVentesAnnee(token);
      final resHebdo = await api.getVentesHebdomadaires(token);

      if (resJour.statusCode == 200 &&
          resAnnee.statusCode == 200 &&
          resHebdo.statusCode == 200) {
        // Traitement des données du jour
        final rawJour = resJour.data;
        List<Map<String, dynamic>> mergedJour = [];
        if (rawJour is List && rawJour.isNotEmpty) {
          final firstItem = rawJour[0];
          final List totalParHeure = firstItem['totalParHeure'] ?? [];
          final List quantiteParHeure = firstItem['quantiteParHeure'] ?? [];

          final Map<int, int> quantiteMap = {
            for (var q in quantiteParHeure)
              (q['_id'] ?? 0) as int: (q['quantite'] ?? 0) as int
          };

          mergedJour = totalParHeure.map<Map<String, dynamic>>((item) {
            final heure = (item['_id'] ?? 0) as int;
            return {
              '_id': heure,
              'total': item['total'] ?? 0,
              'quantite': quantiteMap[heure] ?? 0,
            };
          }).toList();
        }

        // Traitement des données de l'année
        final rawAnnee = resAnnee.data;
        List<Map<String, dynamic>> mergedAnnee = [];
        if (rawAnnee is List && rawAnnee.isNotEmpty) {
          final firstItem = rawAnnee[0];
          final List totalParMois = firstItem['totalParMois'] ?? [];
          final List quantiteParMois = firstItem['quantiteParMois'] ?? [];

          final Map<int, int> quantiteMapAnnee = {
            for (var q in quantiteParMois)
              (q['_id'] ?? 0) as int: (q['quantite'] ?? 0) as int
          };

          mergedAnnee = totalParMois.map<Map<String, dynamic>>((item) {
            final mois = (item['_id'] ?? 0) as int;
            return {
              '_id': mois,
              'total': item['total'] ?? 0,
              'quantite': quantiteMapAnnee[mois] ?? 0,
            };
          }).toList();
        }

        setState(() {
          ventesDuJour = mergedJour;
          ventesAnnee = mergedAnnee;
          ventesHebdo = List<Map<String, dynamic>>.from(resHebdo.data);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
  }

  Widget _buildCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[600])),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Statistiques Générales",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xff001c30),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtre par mois
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonFormField(
                value: selectedMonth,
                items: moisFiltres.map((m) {
                  return DropdownMenuItem(
                    value: m["value"],
                    child: Text(m["label"], style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value! as String;
                    _fetchStats();
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Filtrer par mois",
                  prefixIcon: Icon(Icons.date_range),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Première ligne: BarChart + (2 cartes + graph journalier)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BarChart hebdo (70% de largeur)
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📊 Statistiques hebdomadaires",
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _buildBarChart(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Colonne avec 2 cartes + graph journalier (30% de largeur)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCard("📦 Total des produits", "$totalPiecesEnStock",
                          Icons.inventory_rounded, Colors.blue),
                      const SizedBox(height: 4),
                      _buildCard("📦 Variétes en stock", "$produitsEnStock",
                          Icons.inventory, Colors.teal),
                      const SizedBox(height: 4),
                      _buildCard("⛔ En rupture", "$produitsRupture",
                          Icons.warning, Colors.red),
                      const SizedBox(height: 8),
                      Text("📅 Ventes du jour",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        // padding: const EdgeInsets.all(8),
                        height:
                            150, // Hauteur réduite pour le graphique journalier
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: _buildChartJour(ventesDuJour),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Deuxième ligne: Grille avec 6 cartes (3x2)
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 6, // Ratio 1/2 comme demandé
              children: [
                _buildCard(
                    "👥 Clients", "$nombreClients", Icons.people, Colors.blue),
                _buildCard(
                    "📈 Coût d'achat globale",
                    _formatPrice.formatNombre(coutAchatTotal.toString()),
                    Icons.trending_up,
                    Colors.purple),
                _buildCard("🧾 Nombre de ventes", "$nombreVentes",
                    Icons.receipt_long, Colors.indigo),
                _buildCard(
                    "💰 Total ventes",
                    _formatPrice.formatNombre(totalVentes.toString()),
                    Icons.attach_money,
                    Colors.green),
                _buildCard(
                    "📥 Montant encaissé",
                    _formatPrice.formatNombre(montantEncaisse.toString()),
                    Icons.payments,
                    Colors.teal),
                _buildCard(
                    "🧾Total crédit impayés",
                    _formatPrice.formatNombre(resteTotal.toString()),
                    Icons.pending_actions,
                    Colors.redAccent),
                _buildCard(
                    "👥 Total rembourser",
                    _formatPrice.formatNombre(montantRembourse.toString()),
                    FontAwesomeIcons.replyAll,
                    Colors.blue),
                _buildCard(
                    "🏦 Remises totales",
                    _formatPrice.formatNombre(totalRemises.toString()),
                    Icons.savings,
                    Colors.orange),
                _buildCard(
                    "🏦 Totales Tva collectée",
                    _formatPrice.formatNombre(totalTVACollectee.toString()),
                    Icons.receipt,
                    Colors.deepPurple),
                _buildCard("📅 Produit perdu", "$quantitePertes ",
                    Icons.warning, Colors.yellow),
                _buildCard(
                    "💳 Montant perdu",
                    _formatPrice.formatNombre(coutAchatPertes.toString()),
                    Icons.trending_down,
                    Colors.red),
                _buildCard(
                    "💸 Dépenses",
                    _formatPrice.formatNombre(totalDepenses.toString()),
                    Icons.money_off,
                    Colors.brown),
                _buildCard(
                    "💼 Bénéfice",
                    _formatPrice.formatNombre(benefice.toString()),
                    Icons.account_balance_wallet,
                    Colors.deepPurple),
                _buildCard(
                    "📊 Caisse nette (globale du mois)",
                    _formatPrice.formatNombre(etatCaisse.toString()),
                    Icons.account_balance,
                    Colors.pink),
              ],
            ),
            const SizedBox(height: 20),

            // Troisième ligne: LineChart pleine largeur
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📆 Ventes de l'année",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                    height: 250,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: _buildLineChartAnnee(ventesAnnee)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxValue = ventesHebdo.fold(
        0.0, (max, e) => e['total'] > max ? e['total'].toDouble() : max);

    return AspectRatio(
      aspectRatio: 2.63,
      child: Container(
        padding: const EdgeInsets.only(top: 25, bottom: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(207, 65, 71, 124),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: BarChart(
          swapAnimationDuration: const Duration(milliseconds: 20),
          swapAnimationCurve: Curves.linear,
          BarChartData(
            minY: 0,
            maxY: maxValue * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dayData = ventesHebdo[groupIndex];
                  return BarTooltipItem(
                    '${[
                      'Lun',
                      'Mar',
                      'Mer',
                      'Jeu',
                      'Ven',
                      'Sam',
                      'Dim'
                    ][groupIndex]}\n'
                    'Total: ${dayData['total']} Fcfa\n'
                    'Quantité: ${dayData['quantity']}',
                    GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final days = [
                      'Lun',
                      'Mar',
                      'Mer',
                      'Jeu',
                      'Ven',
                      'Sam',
                      'Dim'
                    ];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[value.toInt()],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: ventesHebdo.map((data) {
              return BarChartGroupData(
                x: data['day'],
                barRods: [
                  BarChartRodData(
                    toY: data['total'].toDouble(),
                    width: 50,
                    gradient: const LinearGradient(
                      colors: [
                        // Colors.blue.shade400,
                        // Colors.blue.shade800,
                        Colors.amber,
                        Colors.red,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.1, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue * 1.2,
                      color: const Color.fromARGB(24, 3, 3, 3),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChartJour(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          borderRadius: BorderRadius.circular(10)),
      child: BarChart(
        swapAnimationDuration: const Duration(milliseconds: 20),
        swapAnimationCurve: Curves.linear,
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final heure = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 7.0),
                    child: Text("$heure h",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final heure = group.x;
                final total = rod.toY;
                final item = data.firstWhere((el) => el['_id'] == heure,
                    orElse: () => {});
                final quantite = item['quantite'] ?? 0;

                return BarTooltipItem(
                  "Heure: $heure h\nTotal: ${total.toStringAsFixed(0)} Fcfa\nQté: $quantite",
                  GoogleFonts.poppins(color: Colors.white),
                );
              },
            ),
          ),
          barGroups: data.map((e) {
            final x = (e['_id'] ?? 0) is int
                ? e['_id']
                : int.tryParse('${e['_id']}') ?? 0;
            final y =
                (e['total'] ?? 0) is num ? (e['total'] as num).toDouble() : 0.0;

            return BarChartGroupData(
              x: x,
              barRods: [
                BarChartRodData(
                  toY: y,
                  gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChartAnnee(List<Map<String, dynamic>> rawData) {
    // 1. Compléter les données manquantes avec total = 0 si absent
    final data = List.generate(12, (i) {
      final mois = i + 1;
      final found =
          rawData.firstWhere((e) => e['_id'] == mois, orElse: () => {});
      return {
        '_id': mois,
        'total': found['total'] ?? 0,
        'quantite': found['quantite'] ?? 0,
      };
    });

    // 2. Convertir en FlSpot
    final spots = data.map((e) {
      return FlSpot(e['_id'] * 1.0, (e['total'] as num).toDouble());
    }).toList();

    final currentMonth = DateTime.now().month;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff001c30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 29, 28, 28).withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: LineChart(
        duration: const Duration(milliseconds: 20),
        curve: Curves.easeOut,
        LineChartData(
          minX: 1,
          maxX: 12,
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.redAccent, Colors.orangeAccent],
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.redAccent.withOpacity(.4),
                    Colors.orangeAccent.withOpacity(.4),
                  ],
                ),
                applyCutOffY: true,
              ),
              preventCurveOverShooting: true,
              preventCurveOvershootingThreshold: 5.9,
              dotData: const FlDotData(
                show: true,
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: 1,
                getTitlesWidget: (value, _) {
                  const moisLabels = [
                    'Jan',
                    'Fév',
                    'Mar',
                    'Avr',
                    'Mai',
                    'Juin',
                    'Juil',
                    'Aoû',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Déc'
                  ];
                  final index = value.toInt() - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      (index >= 0 && index < 12) ? moisLabels[index] : '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: value.toInt() == currentMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: value.toInt() == currentMonth
                            ? Colors.orange
                            : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> indicators) {
              return indicators.map((int index) {
                // final spot = barData.spots[index];
                return const TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent, strokeWidth: 0),
                  FlDotData(show: true),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.x.toInt() - 1;
                  final moisData = data[index];
                  final mois =
                      DateFormat.MMM('fr_FR').format(DateTime(2025, index + 1));
                  return LineTooltipItem(
                    "$mois\n"
                    "Montant: ${moisData['total']} Fcfa\n"
                    "Qté: ${moisData['quantite']}",
                    const TextStyle(color: Color.fromRGBO(255, 167, 51, 1)),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
