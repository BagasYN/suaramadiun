import 'package:permission_handler/permission_handler.dart';

void requestPermissions() async {
  // Memeriksa dan meminta izin yang diperlukan
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.photos,
    Permission.mediaLibrary,
    Permission.accessMediaLocation,
  ].request();

  // Cek apakah izin diberikan atau tidak
  if (statuses[Permission.camera]?.isGranted == false) {
    print('Permission to access camera is denied');
  }
  if (statuses[Permission.storage]?.isGranted == false) {
    print('Permission to access storage is denied');
  }
  if (statuses[Permission.photos]?.isGranted == false) {
    print('Permission to access photos is denied');
  }
  if (statuses[Permission.mediaLibrary]?.isGranted == false) {
    print('Permission to access media library is denied');
  }
  if (statuses[Permission.accessMediaLocation]?.isGranted == false) {
    print('Permission to access media location is denied');
  }
}
