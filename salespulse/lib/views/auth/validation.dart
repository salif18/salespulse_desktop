import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/login_view.dart';

class ValidationReset extends StatefulWidget {
  const ValidationReset({super.key});

  @override
  State<ValidationReset> createState() => _ValidationResetState();
}

class _ValidationResetState extends State<ValidationReset> {
  ServicesAuth api = ServicesAuth();

  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String resetTokenValue = "";

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

// ENVOIE DES DONNEE VERS API SERVER
  Future<void> _sendToserver(BuildContext context) async {
    if (_globalKey.currentState!.validate()) {
      var data = {
        "reset_token": resetTokenValue,
        "new_password": _newPassword.text.trim(),
        "confirm_password": _confirmPassword.text.trim()
      };

      try {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            });
        final response = await api.postValidatePassword(data);
        final body = json.decode(response.body);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (response.statusCode == 200) {
          // ignore: use_build_context_synchronously
          api.showSnackBarSuccessPersonalized(context, body["message"]);
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginView()));
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, body["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialogue
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, "Erreur: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: const Color(0xff001c30),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24, color: Colors.white,)),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(20)
             ),
            width: 400,
            child: Center(
              child: Form(
                key: _globalKey,
                child: Column(
                  children: [
                    _text(context),
                    _formNewPassword(context),
                    _formConfirmPassword(context),
                    _secondText(context),
                    _codes4Champs(context),
                    const SizedBox(height: 50),
                    _sendButton(context)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Validation le mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                "Veuillez entrer les bonnes informations pour pouvoir valider le nouveau mot de passe",
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.w300)),
          ),
        ],
      ),
    );
  }

  Widget _formNewPassword(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 400,
        child: TextFormField(
          controller: _newPassword,
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez entrer un nouveau mot de passe';
            }
            return null;
          },
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.key_rounded, size: 24),
            filled: true,
            fillColor: Colors.grey[100],
            labelText: "Nouveau mot de passe",
            labelStyle:
                GoogleFonts.aBeeZee(fontSize: 14, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _formConfirmPassword(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 400,
        child: TextFormField(
          controller: _confirmPassword,
          validator: (value) {
            if (value!.isEmpty) {
              return 'Veuillez retaper le meme mot de passe';
            }
            return null;
          },
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 24),
            filled: true,
            fillColor: Colors.grey[100],
            labelText: "Confirmer",
            labelStyle:
                GoogleFonts.aBeeZee(fontSize: 14, fontWeight: FontWeight.w500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _secondText(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Text("Entrez les 4 chiffres envoyés sur votre e-mail",
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.w400))));
  }

  Widget _codes4Champs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: 400,
          padding: const EdgeInsets.all(8.0),
          child: PinCodeTextField(
            appContext: context,
            length: 4,
            pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 80,
                fieldWidth: 75,
                activeColor: Colors.blue,
                inactiveColor: Colors.grey),
            onCompleted: (value) {
              setState(() {
                resetTokenValue = value;
              });
            },
            validator: (value) {
              if (value!.isEmpty) {
                return 'Veuillez entrer les 4 chiffres de validation';
              }
              return null;
            },
          )),
    );
  }

  Widget _sendButton(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 115, 0),
            minimumSize: const Size(350, 50)),
        onPressed: () {
          _sendToserver(context);
        },
        child: Text("Envoyer",
            style: GoogleFonts.aBeeZee(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white)));
  }
}
