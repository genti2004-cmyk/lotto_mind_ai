import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WestlottoLauncherService {
  const WestlottoLauncherService._();

  static Future<bool> copyOnly(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  static Future<bool> open(String text) async {
    return openWestlotto();
  }

  static Future<bool> openWestlotto() async {
    final uri = Uri.parse('https://www.westlotto.de/');
    return _launch(uri);
  }

  static Future<bool> openWithTip({
    required List<int> numbers,
    int? superzahl,
  }) async {
    final cleanedNumbers = numbers.toSet().toList()..sort();

    final query = <String, String>{
      'numbers': cleanedNumbers.join(','),
      if (superzahl != null) 'superzahl': superzahl.toString(),
    };

    final uri = Uri.https(
      'www.westlotto.de',
      '/',
      query.isEmpty ? null : query,
    );

    return _launch(uri);
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}