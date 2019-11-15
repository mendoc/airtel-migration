import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class Accueil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airtel Migration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
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

void _showDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // return object of type Dialog
      return AlertDialog(
        title: new Text("Succès"),
        content: new Text("Vos contacts ont bien été mis à jour."),
        actions: <Widget>[
          // usually buttons at the bottom of the dialog
          new FlatButton(
            child: new Text("Fermer", style: TextStyle(color: Colors.red),),
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

  refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _getNumbers();
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future _createContact(Contact contact) async {
    Contact c = contact;
    await ContactsService.deleteContact(contact);
    ContactsService.addContact(c);
  }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return int.parse(s, radix: 10, onError: (e) {
          return null;
        }) !=
        null;
  }

  Future _getNumbers() async {
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    contacts = contacts.take(12);
    int n = 1;

    contacts.forEach((contact) {
      Map m = contact.toMap();
      var nums = [];
      bool updated = false;
      Iterable<Item> phones = contact.phones;
      phones.forEach((phone) {
        numeros.clear();
        numeros.add(phone.value);

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
            if (!contact.phones.contains(Item.fromMap(it))) {
              if (!nums.contains(it)) nums.add(it);
              updated = true;
            }

            print(contact.toString());

            print(contact.displayName +
                " => " +
                numeroCour +
                " => " +
                maisonCour);
          }
        }
      });
      if (updated) {
        for (Item p in contact.phones ?? []) {
          nums.add({"label": p.label, "value": p.value});
        }
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
    _showDialog(this.context);
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ??
          PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (permissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Text("Airtel Migration")),
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
                                  ready = false;
                                  finished = false;
                                  refreshContacts();
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(width: 1, color: Colors.red),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0, horizontal: 5.0),
                                  child: Center(
                                    child: Text(
                                      "Mettre à jour mes contacts",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 30.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0, horizontal: 5.0),
                                  child: Center(
                                    child: Text(
                                      "Restaurer mes contacts",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(width: 1, color: Colors.red),
                                color: Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20.0, horizontal: 5.0),
                                child: Center(
                                  child: Text(
                                    "Partager mon numero",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
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
                                            TextStyle(color: Color(0xffE30512)),
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
                                            TextStyle(color: Color(0xffE30512)),
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
                        child: Text("Migration en cours ..."),
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
