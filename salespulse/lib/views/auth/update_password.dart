// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/reset_password.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
    ServicesAuth api = ServicesAuth();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _passwordConfirmation = TextEditingController();

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future _sendUpdate() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AuthProvider>(context, listen: false);
      final userId = provider.userId;
      final token = provider.token;
      var data = {
        "current_password": _currentPassword.text,
        "new_password": _newPassword.text,
        "confirm_password": _passwordConfirmation.text
      };
      try {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            });
        final res = await api.postUpdatePassword(data,token, userId);
        final decodedData = json.decode(res.body);
          Navigator.pop(context); // Fermer le dialog

        if (res.statusCode == 200) {
          api.showSnackBarSuccessPersonalized(
              context, decodedData['message'].toString());
         Navigator.pop(context);
        } else {
          api.showSnackBarErrorPersonalized(
              context, decodedData["message"].toString());
        }
      } catch (err) {
        api.showSnackBarErrorPersonalized(context,
            "Erreur lors de l'envoi des données , veuillez réessayer. $err");
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1A30),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 24, color: Colors.white,)),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [_formulaires(context)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulaires(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Changer de mot de passe",
                  style: GoogleFonts.roboto(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Votre mot de passe doit contenir au moins 6 caractères",
                  style: GoogleFonts.roboto(
                      fontSize: 14, fontWeight: FontWeight.w400),
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            width: 400,
            child: TextFormField(
               controller: _currentPassword,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez entrer un mot de passe actuel';
                }
                return null;
              },
              keyboardType: TextInputType.visiblePassword,
              obscureText: false,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: "Mot de passe actuel",
                hintStyle: GoogleFonts.aBeeZee(
                    fontSize: 14, fontWeight: FontWeight.w400),
                // prefixIcon: const Icon(Icons.lock_outline_rounded, size: 33),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            width: 400,
            child: TextFormField(
              controller: _newPassword,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez rentrer un nouveau mot de passe';
                }
                return null;
              },
              keyboardType: TextInputType.visiblePassword,
              obscureText: false,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: "Nouveau mot de passe",
                hintStyle: GoogleFonts.aBeeZee(
                    fontSize: 14, fontWeight: FontWeight.w400),
                // prefixIcon: const Icon(Icons.lock_outline_rounded, size: 33),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            width: 400,
            child: TextFormField(
               controller: _passwordConfirmation,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez retaper le meme mot de passe';
                }
                return null;
              },
              keyboardType: TextInputType.visiblePassword,
              obscureText: false,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                hintText: "Retapez le nouveau mot de passe",
                hintStyle: GoogleFonts.aBeeZee(
                    fontSize:14, fontWeight: FontWeight.w400),
                // prefixIcon: const Icon(Icons.lock_outline_rounded, size: 33),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ResetToken()));
                },
                child: Text("Mot de passe oublié ?",
                    style: GoogleFonts.roboto(fontSize: 14)))
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 115, 0),
              elevation: 5,
              fixedSize: const Size(400, 50),
            ),
            onPressed: () {
              _sendUpdate();
            },
            child: Text(
              "Changer le mot de passe",
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[100],
              ),
            ),
          ),
        )
      ],
    );
  }
}
