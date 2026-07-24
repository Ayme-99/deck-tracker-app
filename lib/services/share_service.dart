import 'package:share_plus/share_plus.dart';

/// Envoltorio fino sobre share_plus (issue #130), para no acoplar las
/// pantallas directamente al plugin.
class ShareService {
  Future<void> shareText(String text) => Share.share(text);
}
