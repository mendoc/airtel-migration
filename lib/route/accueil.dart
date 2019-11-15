import 'package:change_contacts/ui/bouton.dart';
import 'package:change_contacts/util/config.dart';
import 'package:change_contacts/util/master.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

class Accueil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airtel Migration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(accentColor: Colors.red),
      home: AccueilPage(title: 'Airtel Migration'),
    );
  }
}

class AccueilPage extends StatefulWidget {
  final String title;

  AccueilPage({Key key, this.title}) : super(key: key);

  @override
  _AccueilPageState createState() => _AccueilPageState();
}

void _showDialog(BuildContext context, {String message}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: new Text("Succès"),
        content: new Text(message ?? "Vos contacts ont bien été mis à jour."),
        actions: <Widget>[
          new FlatButton(
            child: new Text(
              "Fermer",
              style: TextStyle(color: mainColor),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void _showAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(
            "Veuillez patienter \nCette opération peut prendre du temps..."),
      );
    },
  );
}

class _AccueilPageState extends State<AccueilPage> {
  final myController = TextEditingController();

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  refreshContacts(bool t) async {
    PermissionStatus permissionStatus = await getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _getNumbers(test: t);
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  void _displayDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Votre nouveau numéro de téléphone'),
          content: TextField(
            controller: myController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: "ex: +24174212121"),
          ),
          actions: <Widget>[
            FlatButton(
              child: new Text(
                'Fermer',
                style: TextStyle(color: Color(0xFFAAAAAA)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: new Text(
                'Partager',
                style: TextStyle(color: mainColor),
              ),
              onPressed: () {
                if (myController.text.length == 12) {
                  shareMyNumber(myController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmation(
    BuildContext context,
    action(), {
    String message,
    String titre = "",
    String textAction = "",
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(titre),
          content: new Text(message ?? ""),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                "Fermer",
                style: TextStyle(color: Color(0xAF000000)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                textAction ?? "",
                style: TextStyle(color: mainColor),
              ),
              onPressed: () {
                action();
                Navigator.of(context).pop();
                _showAlert(context);
              },
            ),
          ],
        );
      },
    );
  }

  backupContacts() async {
    PermissionStatus permissionStatus = await getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _restoreNumbers(test: false);
      //final isolate = await FlutterIsolate.spawn(restauration, true);
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  Future _createContact(Contact contact, bool last, {restore = false}) async {
    Contact c = contact;
    await ContactsService.deleteContact(contact);
    await ContactsService.addContact(c);
    print(contact.displayName);
    setState(() {
      if (last) {
        Navigator.of(context, rootNavigator: true).pop();
        restore
            ? _showDialog(this.context,
                message: "Vos contacts ont bien été restaurés")
            : _showDialog(this.context);
      }
    });
  }

  Future _getNumbers({test = true}) async {
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    if (test) contacts = contacts.take(10);

    contacts.forEach((contact) {
      Map m = contact.toMap();
      List<Map> nums = [];
      bool updated = false;
      Iterable<Item> phones = contact.phones;
      numeros.clear();
      phones.forEach((phone) {
        String p = phone.value.replaceAll(" ", "");
        if (!numeros.contains(p)) numeros.add(p);
      });

      // Lister les numéro
      String numeroCour;
      int tailleCour;
      String maisonCour;
      bool inter;

      for (var i = 0; i < numeros.length; i++) {
        inter = false;
        // Vérifier si c’est un numéro gabonais
        numeroCour = numeros.elementAt(i);
        // Epurer le numéro
        numeroCour = numeroCour.replaceAll(" ", "");
        tailleCour = numeroCour.length;
        // vérifier la taille
        switch (tailleCour) {
          case 13:
            {
              if (numeroCour.startsWith("002410")) {
                numeroCour = numeroCour.substring(5);
                inter = true;
              }
            }
            break;
          case 12:
            {
              if (numeroCour.startsWith("+2410")) {
                numeroCour = numeroCour.substring(4);
                inter = true;
              }
            }
            break;
          case 11:
            {
              if (numeroCour.startsWith("2410")) {
                numeroCour = numeroCour.substring(3);
                inter = true;
              }
            }
            break;
        }

        if (numeroCour.length == 8 &&
            numeroCour.startsWith("0") &&
            isNumeric(numeroCour)) {
          maisonCour = numeroCour.substring(1, 2);

          if (maisonCour == "1") {
            numeroCour = "1" + numeroCour.substring(1);
          } else if (maisonCour == "2" ||
              maisonCour == "5" ||
              maisonCour == "6") {
            numeroCour = "6" + numeroCour.substring(1);
          } else if (maisonCour == "4" || maisonCour == "7") {
            numeroCour = "7" + numeroCour.substring(1);
          } else if (maisonCour == "3") continue;

          if (inter)
            numeroCour = "+241" + numeroCour;
          else {
            if (maisonCour != "3") {
              numeroCour = "0" + numeroCour;
            }
          }

          Map it = {"label": "other", "value": numeroCour};
          if (!numeros.contains(numeroCour)) {
            if (!nums.contains(it)) nums.add(it);
            updated = true;
          }
          /*print(
              contact.displayName + " => " + numeroCour + " => " + maisonCour);*/
        }
      }
      if (updated) {
        for (Item p in contact.phones ?? []) {
          if (!nums.contains({"label": p.label, "value": p.value}))
            nums.add({"label": p.label, "value": p.value});
        }
        m["phones"] = nums;

        _createContact(Contact.fromMap(m), contacts.last == contact);
      } else {
        print(contact.displayName);
        setState(() {
          if (contacts.last == contact) {
            Navigator.of(context, rootNavigator: true).pop();
            _showDialog(this.context);
          }
        });
      }
    });
  }

  void shareMyNumber(String number) {
    String text =
        "Voici mon nouveau numéro de téléphone, prière de l'ajouter dans votre répertoire s'il vous plaît. Merci\n";
    text += number;
    Share.share(text);
  }

  Future _restoreNumbers({test: true}) async {
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    if (test) contacts = contacts.take(15);

    contacts.forEach((contact) {
      Map m = contact.toMap();
      List<Map> nums = [];
      bool updated = false;
      Iterable<Item> phones = contact.phones;
      numeros.clear();
      phones.forEach((phone) {
        String p = phone.value.replaceAll(" ", "");
        if (isGaboneseNumber(p)) {
          Map it = {"label": phone.label, "value": phone.value};
          nums.add(it);
        } else {
          if (isNewFormat(p)) updated = true;
        }
      });

      if (nums.length > 0 && updated) {
        m["phones"] = nums;
        _createContact(Contact.fromMap(m), contacts.last == contact,
            restore: true);
      } else {
        setState(() {
          if (contacts.last == contact) {
            Navigator.of(context, rootNavigator: true).pop();
            _showDialog(this.context,
                message: "Vos contacts ont bien été restaurés");
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(
            child: Image.asset(
          "assets/img/airtel_logo_blanc.png",
          width: 45.0,
        )),
      ),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Align(
            alignment: Alignment(0, 1),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          InkWell(
                            onTap: () {
                              _showConfirmation(
                                this.context,
                                () {
                                  setState(() {
                                    refreshContacts(true);
                                  });
                                },
                                textAction: "Faire le test",
                                titre: "Test de migration",
                                message:
                                    "Voulez-vous vraiment faire un test de mise à jour de vos contacts ?",
                              );
                            },
                            child: BoutonAirtel("Tester avec 10 contacts"),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0),
                            child: InkWell(
                              onTap: () {
                                _showConfirmation(
                                  this.context,
                                  () {
                                    setState(() {
                                      refreshContacts(false);
                                    });
                                  },
                                  textAction: "Mettre à jour",
                                  titre: "Mise à jour",
                                  message:
                                      "Voulez-vous vraiment faire la mise à jour de tous vos contacts ?",
                                );
                              },
                              child: BoutonAirtel("Mettre à jour tous mes contacts",
                                  red: true),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30.0),
                            child: InkWell(
                              onTap: () {
                                _showConfirmation(
                                  this.context,
                                  () {
                                    setState(() {
                                      backupContacts();
                                    });
                                  },
                                  titre: "Restauration",
                                  textAction: "Restaurer",
                                  message:
                                      "Voulez-vous vraiment restaurer vos contacts ?",
                                );
                              },
                              child: BoutonAirtel("Restaurer mes contacts"),
                            ),
                          ),
                          InkWell(
                              onTap: () {
                                _displayDialog(context);
                              },
                              child:
                                  BoutonAirtel("Partager mon numéro", red: true)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.12,
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Color(0xffcccccc))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Center(
                            child: InkWell(
                              onTap: () {
                                AlertDialog diag = AlertDialog(
                                  content: Text(
                                      "Veuillez patienter \nCette opération peut prendre du temps..."),
                                );
                                diag.build(context);
                              },
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 25.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6.0),
                                        child: Image.asset(
                                          "assets/img/more.png",
                                          width: 25.0,
                                        ),
                                      ),
                                      Text(
                                        "Plus d'informations",
                                        style: TextStyle(color: mainColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: InkWell(
                              onTap: () {
                                Share.share(
                                    'Téléchargez Airtel Migration sur https://airtel-migration.netlify.com');
                              },
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 25.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6.0),
                                        child: Image.asset(
                                          "assets/img/share.png",
                                          width: 25.0,
                                        ),
                                      ),
                                      Text(
                                        "Partager l'application",
                                        style: TextStyle(color: mainColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
