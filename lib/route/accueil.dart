import 'package:change_contacts/ui/bouton.dart';
import 'package:change_contacts/util/master.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:change_contacts/util/config.dart';

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

class _AccueilPageState extends State<AccueilPage> {
  bool ready = true;
  bool finished = false;
  String progress = "0%";
  String status = "Migration en cours ...";

  refreshContacts(bool t) async {
    PermissionStatus permissionStatus = await getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _getNumbers(test: t);
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  backupContacts() async {
    PermissionStatus permissionStatus = await getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _restoreNumbers(test: false);
    } else {
      handleInvalidPermissions(permissionStatus);
    }
  }

  Future _createContact(Contact contact) async {
    Contact c = contact;
    await ContactsService.deleteContact(contact);
    ContactsService.addContact(c);
  }

  Future _getNumbers({test = true}) async {
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    if (test) contacts = contacts.take(10);
    int n = 1;

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

      print(numeros);

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
          print(
              contact.displayName + " => " + numeroCour + " => " + maisonCour);
        }
      }
      if (updated) {
        for (Item p in contact.phones ?? []) {
          if (!nums.contains({"label": p.label, "value": p.value}))
            nums.add({"label": p.label, "value": p.value});
        }
        m["phones"] = nums;
        print(nums);
        _createContact(Contact.fromMap(m));
      }
      setState(() {
        progress = ((n / contacts.length) * 100).toString() + "%";
      });
      n++;
    });
    setState(() {
      ready = true;
    });
    _showDialog(this.context);
  }

  Future _restoreNumbers({test: true}) async {
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    if (test) contacts = contacts.take(15);
    int n = 1;

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
        _createContact(Contact.fromMap(m));
      }
      setState(() {
        progress = ((n / contacts.length) * 100).toString() + "%";
      });
      n++;
    });
    setState(() {
      ready = true;
    });
    _showDialog(this.context, message: "Vos contacts ont bien été restaurés");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Image.asset(
          "assets/img/airtel_logo_blanc.png",
          width: 45.0,
        )),
      ),
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: ready
              ? Column(
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
                                setState(() {
                                  progress = "0%";
                                  status = "Test en cours ...";
                                  ready = false;
                                  refreshContacts(true);
                                });
                              },
                              child: BoutonAirtel("Tester avec 10 contacts"),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    progress = "0%";
                                    status = "Migration en cours ...";
                                    ready = false;
                                    refreshContacts(false);
                                  });
                                },
                                child: BoutonAirtel("Mettre à jour tous mes contacts", red: true),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 30.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    progress = "0%";
                                    status = "Restauration en cours ...";
                                    ready = false;
                                    backupContacts();
                                  });
                                },
                                child: BoutonAirtel("Restaurer mes contacts"),
                              ),
                            ),
                            BoutonAirtel("Partager mon numéro", red: true),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Container(
                        decoration: BoxDecoration(
                            border:
                                Border.all(width: 1, color: Color(0xffcccccc))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Center(
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
                                        style:
                                            TextStyle(color: mainColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
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
                                        style:
                                            TextStyle(color: mainColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(status),
                      ),
                      Text(
                        progress,
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
