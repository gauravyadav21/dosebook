import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin wrappers around phone features. They are variables so widget tests can replace them.
class PickedFile {
  PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

typedef FilePickerFn = Future<PickedFile?> Function();

/// Lets the user choose one prescription photo or PDF.
FilePickerFn pickPrescriptionFile = () async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
  );
  if (file == null) return null;
  return PickedFile(file.name, await file.readAsBytes());
};

/// Opens the phone dialler with the number filled in. The user still presses call.
Future<bool> Function(String phone) openDialler = (phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  return launchUrl(Uri(scheme: 'tel', path: digits));
};

/// Hands text to the system share sheet.
Future<void> Function(String text) shareText = (text) async {
  await SharePlus.instance.share(ShareParams(text: text));
};
