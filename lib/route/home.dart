import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:permission_handler/permission_handler.dart';

class Home extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airtel Migration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Airtel Migration'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Iterable<Contact> _contacts;

  @override
  initState() {
    super.initState();
    loadContacts();
  }

  loadContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var contacts = await ContactsService.getContacts();
      contacts = contacts.take(10);
      setState(() {
        _contacts = contacts;
      });
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      _getNumbers();
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
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
    setState(() {
      _contacts = null;
    });
    List<String> numeros = [];
    Iterable<Contact> contacts = await ContactsService.getContacts(
        withThumbnails: false, photoHighResolution: false);
    contacts = contacts.take(12);

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
              nums.add(it);
              updated = true;
            }

            print(contact.toString());
            //print(contact.phones.elementAt(0).value);
            //print(contact.phones.elementAt(1).value);

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
    });
    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Text(widget.title)),
      ),
      body: SafeArea(
        child: _contacts != null
            ? ListView.builder(
                itemCount: _contacts?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  Contact c = _contacts?.elementAt(index);
                  List<String> nums = [];
                  c.phones.forEach((it) {
                    nums.add(it.value);
                  });
                  return ListTile(
                    onTap: () {
                      /*Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) =>
                        Text('Salut')));*/
                    },
                    leading: (c.avatar != null && c.avatar.length > 0)
                        ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                        : CircleAvatar(child: Text(c.initials())),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(c.displayName ?? ""),
                        Text(nums.join(", ") ?? ""),
                      ],
                    ),
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          refreshContacts();
        },
        tooltip: 'Increment',
        child: Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
