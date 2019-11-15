
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

bool isGaboneseNumber(String num) {
  num = num.replaceAll(" ", "");
  int tailleCour = num.length;

  switch (tailleCour) {
    case 13:
      {
        if (num.startsWith("002410")) {
          num = num.substring(5);
        }
      }
      break;
    case 12:
      {
        if (num.startsWith("+2410")) {
          num = num.substring(4);
        }
      }
      break;
    case 11:
      {
        if (num.startsWith("2410")) {
          num = num.substring(3);
        }
      }
      break;
  }

  return num.length == 8 && num.startsWith("0") && isNumeric(num);
}

bool isNewFormat(String num) {
  num = num.replaceAll(" ", "");
  int tailleCour = num.length;
  bool inter = false;

  switch (tailleCour) {
    case 13:
      {
        if (num.startsWith("00241")) {
          num = num.substring(5);
          inter = true;
        }
      }
      break;
    case 12:
      {
        if (num.startsWith("+241")) {
          num = num.substring(4);
          inter = true;
        }
      }
      break;
  }

  if (inter) num = "0" + num;

  return num.length == 9 && num.startsWith("0") && isNumeric(num) && (num.startsWith("07") || num.startsWith("06"));
}

Future<PermissionStatus> getContactPermission() async {
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

void handleInvalidPermissions(PermissionStatus permissionStatus) {
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

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return int.parse(s, radix: 10, onError: (e) {
    return null;
  }) !=
      null;
}
