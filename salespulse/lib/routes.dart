import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/add_photo.dart';
import 'package:salespulse/providers/auth_provider.dart';
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
                _buildPermanentSidebar(), // 👉 menu latéral
                Expanded(child: _buildPage()), // 👉 page principale
              ],
            ),
          )
        : const LoginView(); // 🔒 Si pas connecté
  }

  Widget _buildPermanentSidebar() {
    // Utiliser Consumer pour récupérer les données du panier
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final number =
        Provider.of<AuthProvider>(context, listen: false).societeNumber;
    return Container(
      width: 250,
      color: const Color(0xff001c30),
      child: ListView(
        children: [
          // ✅ Store Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xff001c30),
              border: Border(
                bottom: BorderSide(width: 2, color: Colors.orange),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PikedPhoto(),
                const SizedBox(height: 10,),
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

          // ✅ Navigation
          _buildDrawerItem(
              Icons.stacked_bar_chart_rounded, "Tableau de bord", 0,
              iconBgColor: Colors.orange),
           _buildDrawerItem( Icons.shopping_cart_outlined, "Point de vente", 1,
              iconBgColor: Colors.teal, ),
          _buildDrawerItem(Icons.assured_workload_rounded, "Entrepots", 2,
              iconBgColor: Colors.blue),
           _buildDrawerItem(Icons.add, "Ajouter produits", 3,
              iconBgColor: Colors.blue),
          _buildDrawerItem(Icons.inventory_2_rounded, "Inventaires", 4,
              iconBgColor: Colors.deepPurple),
              _buildDrawerItem(Icons.assignment_add, "Mouvement inventaires", 5,
              iconBgColor: Colors.deepOrange),
          _buildDrawerItem(Icons.category, "Catégories", 6,
              iconBgColor: Colors.green),
          _buildDrawerItem(Icons.library_books_sharp, "Historique de ventes", 7,
              iconBgColor: Colors.cyan),
                _buildDrawerItem(Icons.credit_card_off, "Clients impayés", 8,
              iconBgColor: Colors.yellow),
          _buildDrawerItem(Icons.workspace_premium, "Tendance des produits", 9,
              iconBgColor: Colors.pink),
          _buildDrawerItem(Icons.balance_sharp, "Dépenses", 10,
              iconBgColor: Colors.redAccent),
          _buildDrawerItem(Icons.contact_phone_rounded, "Fournisseurs", 11,
              iconBgColor: Colors.grey),
           _buildDrawerItem(Icons.contact_phone_rounded, "Mes clients", 12,
              iconBgColor: Colors.teal),
          _buildDrawerItem(
              FontAwesomeIcons.handshake, "Règlements de dette", 13,
              iconBgColor: Colors.deepOrange),
            _buildDrawerItem(
              FontAwesomeIcons.userGroup, "Utilisateurs", 14,
              iconBgColor: Colors.deepOrange),
          const Divider(color: Colors.grey),

          // ✅ Bloc actions utilisateur (profil)
          Column(
            children: [
              _customSidebarAction(
                icon: LineIcons.userEdit,
                label: "Modifier profil",
                color: const Color.fromARGB(255, 10, 165, 226),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpdateProfil()),
                ),
              ),
              _customSidebarAction(
                icon: LineIcons.edit,
                label: "Modifier password",
                color: const Color.fromARGB(255, 7, 185, 75),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UpdatePassword()),
                ),
              ),
              _customSidebarAction(
                icon: LineIcons.removeUser,
                label: "Supprimer",
                color: const Color.fromARGB(255, 255, 180, 17),
                onTap: () {}
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
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    final pages = [
      const StatistiquesScreen(),
      const AddVenteScreen(),
      const StocksView(),
      const AddProduitPage(),
      const InventaireProPage(),
      const HistoriqueMouvementsScreen(),
      const CategoriesView(),     
      const HistoriqueVentesScreen(),
      const ClientsEnRetardScreen(),
      const StatistiquesProduitsPage(),
      const DepenseScreen(),
      const FournisseurView(),
      const ClientsView(),
      const HistoriqueReglementsScreen(),
      const UserManagementScreen()
    ];
    return pages[_currentIndex];
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
                      // ignore: dead_code
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
                        ? const[
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
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
