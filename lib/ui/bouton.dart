import 'package:change_contacts/util/config.dart';
import 'package:flutter/material.dart';

class BoutonAirtel extends StatelessWidget {
  String texte = "";
  bool red = false;

  BoutonAirtel(this.texte, {this.red = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: red ? Colors.white : mainColor),
        color: red ? mainColor : Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 5.0),
        child: Center(
          child: Text(
            texte,
            style: TextStyle(
                color: red ? Colors.white : mainColor, fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
