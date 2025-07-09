// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/user_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/auth_api.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ServicesAuth api = ServicesAuth();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  String _searchQuery = '';
  String? _selectedRoleFilter;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'admin', 'label': 'Administrateur', 'color': Colors.redAccent},
    {'value': 'manager', 'label': 'Gestionnaire', 'color': Colors.blueAccent},
    {'value': 'employe', 'label': 'Employé', 'color': Colors.green},
    {'value': 'comptable', 'label': 'Comptable', 'color': Colors.purpleAccent},
  ];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
 
    try {
      final res = await api.getUsers(token);

      if (res.statusCode == 200) {
        setState(() {
          _users = (res.data["data"] as List)
              .map((e) => UserModel.fromJon(e))
              .toList();
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint("Erreur fetchUsers: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des utilisateurs: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRole = _selectedRoleFilter == null || user.role == _selectedRoleFilter;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _openAddUserModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddUserModal(onUserAdded: fetchUsers),
    ).then((_) => fetchUsers());
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrer les utilisateurs'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRoleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tous les rôles'),
                      ),
                      ..._roles.map((role) => DropdownMenuItem(
                            value: role['value'],
                            child: Text(role['label']),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRoleFilter = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _selectedRoleFilter = null);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: const Color(0xff001c30),
        title: Text('Gestion des Utilisateurs',style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width:500,child: _buildSearchBar()),
                 IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
            ],
          ),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text('Aucun utilisateur trouvé'))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUserModal,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un utilisateur...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final role = _roles.firstWhere((r) => r['value'] == user.role);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role['color'].withOpacity(0.2),
          child: Text(
            user.name.substring(0, 1),
            style: TextStyle(
              color: role['color'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(user.email),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role['label'],
                style: TextStyle(
                  color: role['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(user.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigation vers le détail de l'utilisateur
        },
      ),
    );
  }
}

class AddUserModal extends StatefulWidget {
  final VoidCallback onUserAdded;

  const AddUserModal({super.key, required this.onUserAdded});

  @override
  State<AddUserModal> createState() => _AddUserModalState();
}

class _AddUserModalState extends State<AddUserModal> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employe';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      final data = {
        "adminId": adminId,
        "name": _nameController.text,
        "numero": _phoneController.text,
        "email": _emailController.text,
        "role": _selectedRole,
        "password": _passwordController.text
      };

      final response = await ServicesAuth().postRegistreUser(data);
      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur créé avec succès!')),
        );
        widget.onUserAdded();
        Navigator.pop(context);
      } else {
        throw Exception(body["message"] ?? "Erreur inconnue");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ajouter un Utilisateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildAvatarSection(),
        const SizedBox(height: 24),
        _buildTextFormField(
          controller: _nameController,
          label: 'Nom Complet',
          icon: Icons.person_outline,
          validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _emailController,
          label: 'Adresse Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value!.isEmpty) return 'Ce champ est requis';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          controller: _passwordController,
          label: 'Mot de Passe',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) {
            if (value!.isEmpty) return 'Ce champ est requis';
            if (value.length < 6) return 'Minimum 6 caractères';
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildRoleDropdown(),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Ajouter une photo
            },
            child: const Text('Ajouter une photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Rôle',
        prefixIcon: const Icon(Icons.assignment_ind_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: <Map<String, dynamic>>[
        {'value': 'admin', 'label': 'Administrateur', 'icon': Icons.admin_panel_settings},
        {'value': 'manager', 'label': 'Gestionnaire', 'icon': Icons.manage_accounts},
        {'value': 'employe', 'label': 'Employé', 'icon': Icons.person},
        {'value': 'comptable', 'label': 'Comptable', 'icon': Icons.calculate},
      ].map<DropdownMenuItem<String>>((role) => DropdownMenuItem<String>(
            value: role['value'] as String,
            child: Row(
              children: [
                Icon(role['icon']),
                const SizedBox(width: 12),
                Text(role['label']),
              ],
            ),
          )).toList(),
      onChanged: (value) => setState(() => _selectedRole = value!),
      validator: (value) => value == null ? 'Veuillez sélectionner un rôle' : null,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _submitForm(context),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'ENREGISTRER',
              style: TextStyle(fontSize: 16),
            ),
    );
  }
}