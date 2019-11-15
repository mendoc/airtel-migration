import 'package:contacts_service/contacts_service.dart';

import 'master.dart';

void restauration(test) {
  Future<Iterable<Contact>> contactsFuture = ContactsService.getContacts(
      withThumbnails: false, photoHighResolution: false);
  contactsFuture.then((conts) {
    List<String> numeros = [];
    Iterable<Contact> contacts = conts;

    if (test) contacts = contacts.take(15);

    contacts.forEach((contact) {
      print(contact.displayName);
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
        Contact c = Contact.fromMap(m);
        ContactsService.deleteContact(contact);
        ContactsService.addContact(c);
      }
    });
  });
}
