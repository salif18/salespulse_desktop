// ignore_for_file: deprecated_member_use, dead_code

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/add_photo.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/views/abonnement/abonement_historiques.dart';
import 'package:salespulse/views/auth/login_view.dart';
import 'package:salespulse/views/auth/update_password.dart';
import 'package:salespulse/views/categories/categories_view.dart';
import 'package:salespulse/views/cliens/client_pro.dart';
import 'package:salespulse/views/dashbord/dash_prod.dart';
import 'package:salespulse/views/depenses/depense_view.dart';
import 'package:salespulse/views/fournisseurs/fournisseurs_view.dart';
import 'package:salespulse/views/impaye/impaye_pro.dart';
import 'package:salespulse/views/inventaire/inventaire.dart';
import 'package:salespulse/views/mouvements/mouvement_inventaire.dart';
import 'package:salespulse/views/panier/add_vente_pro.dart';
import 'package:salespulse/views/populaires/populaire_view.dart';
import 'package:salespulse/views/profil/update_profil.dart';
import 'package:salespulse/views/reglements/reglement_view.dart';
import 'package:salespulse/views/creer_stocks/add_stock_pro_screen.dart';
import 'package:salespulse/views/stocks/stocks.dart';
import 'package:salespulse/views/users/user_pro.dart';
import 'package:salespulse/views/ventes/historique_vente_pro.dart';

class Routes extends StatefulWidget {
  const Routes({super.key});

  @override
  State<Routes> createState() => _RoutesState();
}

class _RoutesState extends State<Routes> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = Provider.of<AuthProvider>(context).token.isNotEmpty;
    return isLoggedIn
        ? Scaffold(
            body: Row(
              children: [
                _buildPermanentSidebar(),
                Expanded(child: _buildPage()),
              ],
            ),
          )
        : const LoginView();
  }

  Widget _buildPermanentSidebar() {
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final number = Provider.of<AuthProvider>(context, listen: false).societeNumber;
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    final ScrollController scrollController = ScrollController();

    return Container(
      width: 250,
      color: const Color(0xff001c30),
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.white10),
            trackColor: MaterialStateProperty.all(Colors.white10),
            thickness: MaterialStateProperty.all(6),
            radius: const Radius.circular(8),
          ),
        ),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: false,
          trackVisibility: false,
          interactive: true,
          child: ListView(
            controller: scrollController,
            children: [
              // En-tête du magasin
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xff001c30),
                  border: Border(bottom: BorderSide(width: 2, color: Colors.orange)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PikedPhoto(),
                    const SizedBox(height: 10),
                    Text(
                      store,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        number,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 231, 231, 231),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Section ANALYSE
              _buildSectionHeader('ANALYSE'),
              if(role == "admin")
              _buildDrawerItem(Icons.stacked_bar_chart_rounded, "Tableau de bord", 0, iconBgColor: Colors.orange),
              _buildDrawerItem(Icons.workspace_premium, "Tendance des produits", 1, iconBgColor: Colors.pink),

              // Section VENTES
              _buildSectionHeader('VENTES'),
              _buildDrawerItem(Icons.shopping_cart_outlined, "Point de vente", 2, iconBgColor: Colors.teal),
              _buildDrawerItem(Icons.library_books_sharp, "Historique de ventes", 3, iconBgColor: Colors.cyan),
              _buildDrawerItem(Icons.credit_card_off, "Clients impayés", 4, iconBgColor: Colors.orangeAccent),
              _buildDrawerItem(FontAwesomeIcons.handshake, "Historique règlements", 5, iconBgColor: Colors.deepOrange),

              // Section STOCKS
              _buildSectionHeader('STOCKS'),
              _buildDrawerItem(Icons.assured_workload_rounded, "Entrepots", 6, iconBgColor: Colors.blue),
              if(role == "admin")
              _buildDrawerItem(Icons.add, "Ajouter produits", 7, iconBgColor: Colors.blue.shade300),
              _buildDrawerItem(Icons.inventory_2_rounded, "Inventaires", 8, iconBgColor: Colors.deepPurple),
              _buildDrawerItem(Icons.assignment_add, "Mouvement inventaires", 9, iconBgColor: Colors.deepOrange),

              // Section CATALOGUE
              _buildSectionHeader('CATALOGUE'),
              _buildDrawerItem(Icons.category, "Catégories", 10, iconBgColor: Colors.green),

              // Section RELATIONS
              _buildSectionHeader('RELATIONS'),
              _buildDrawerItem(Icons.people_alt, "Mes clients", 11, iconBgColor: Colors.teal),
              _buildDrawerItem(Icons.contact_phone_rounded, "Fournisseurs", 12, iconBgColor: Colors.grey),

              // Section FINANCES
              _buildSectionHeader('FINANCES'),
              _buildDrawerItem(Icons.balance_sharp, "Dépenses", 13, iconBgColor: Colors.redAccent),

              // Section ADMINISTRATION
              _buildSectionHeader('ADMINISTRATION'),
              if(role == "admin")
              _buildDrawerItem(FontAwesomeIcons.userGroup, "Suivis utilisateurs", 14, iconBgColor: Colors.blueAccent),
               if(role == "admin")
              _buildDrawerItem(Icons.receipt_long, "Abonnements", 15, iconBgColor: Colors.deepOrange),


              // Section COMPTE UTILISATEUR
              _buildUserActionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 10, bottom: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserActionsSection() {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        _customSidebarAction(
          icon: LineIcons.userEdit,
          label: "Modifier profil",
          color: const Color.fromARGB(255, 10, 165, 226),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UpdateProfil()),
          )),
        _customSidebarAction(
          icon: LineIcons.edit,
          label: "Modifier password",
          color: const Color.fromARGB(255, 7, 185, 75),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UpdatePassword()),
          )),
        _customSidebarAction(
          icon: LineIcons.removeUser,
          label: "Supprimer compte",
          color: const Color.fromARGB(255, 255, 180, 17),
          onTap: () => _confirmAccountDeletion(),
        ),
        Consumer<AuthProvider>(
          builder: (context, provider, child) => _customSidebarAction(
            icon: LineIcons.alternateSignOut,
            label: "Se déconnecter",
            color: const Color.fromARGB(255, 165, 10, 226),
            onTap: provider.logoutButton,
          ),
        ),
      ],
    );
  }

  Widget _buildPage() {
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.role;

    // Liste complète de toutes les pages avec des index fixes
    final allPages = [
      // 0. Dashboard (admin uniquement)
      const StatistiquesScreen(),
      
      // 1. Tendance des produits
      const StatistiquesProduitsPage(),

      // 2-5. VENTES
      const AddVenteScreen(),
      const HistoriqueVentesScreen(),
      const ClientsEnRetardScreen(),
      const HistoriqueReglementsScreen(),

      // 6-9. STOCKS
      const StocksView(),
      const AddProduitPage(),
      const InventaireProPage(),
      const HistoriqueMouvementsScreen(),

      // 10. CATALOGUE
      const CategoriesView(),

      // 11-12. RELATIONS
      const ClientsView(),
      const FournisseurView(),

      // 13. FINANCES
      const DepenseScreen(),

      // 14. ADMINISTRATION (admin uniquement)
      const UserManagementScreen(),
      const AbonnementHistoriquePage()
    ];

    // Liste des index autorisés selon le rôle
    final allowedIndexes = [
      1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, // Pour tous les utilisateurs
      if (role == "admin") ...[0, 7, 14,15] // Pages supplémentaires pour admin
    ];

    // Vérification si l'index actuel est autorisé
    if (!allowedIndexes.contains(_currentIndex)) {
      // Redirection vers le premier index autorisé
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = allowedIndexes.first;
        });
      });
      return allPages[allowedIndexes.first];
    }

    return allPages[_currentIndex];
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    int index, {
    Widget? trailing,
    Color iconBgColor = Colors.orange,
  }) {
    final isSelected = _currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: StatefulBuilder(
        builder: (context, setStateHover) {
          bool isHovered = false;

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white24
                    : isHovered
                        ? Colors.white10
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 5,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          );
        },
      ),
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
    );
  }

  Widget _customSidebarAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 27,
        width: 27,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}