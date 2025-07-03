import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/routes.dart';


class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 5),
        () => Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const Routes())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff001c30),
      body: AnimatedSwitcher(
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        duration: const Duration(seconds: 5),
        child: Container(
          padding: const EdgeInsets.only(top: 50),
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            key: UniqueKey(),
            children: [
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                            image: AssetImage("assets/logos/logo2.jpg"),
                            fit: BoxFit.contain)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                        child: RichText(
                            text: TextSpan(children: [
                      TextSpan(
                        text: "Sales",
                        style: GoogleFonts.roboto(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff2fc0f2),
                        ),
                      ),
                      TextSpan(
                        text: "Pulse",
                        style: GoogleFonts.roboto(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 255, 123, 0),
                        ),
                      ),
                    ]))),
                  ),
                  SizedBox(
                    child: Text(
                      "Intelligent manager",
                      style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff97e4ff)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
