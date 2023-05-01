import 'dart:async';

import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> redirect(Uri authorizationUrl) async {
  if (await canLaunchUrl(authorizationUrl)) {
    await launchUrl(authorizationUrl);
  }
}

Future<Uri> listen(Uri redirectUrl) async {
  final completer = Completer<Uri>();

  StreamSubscription? linksStreamSubscription;
  linksStreamSubscription = linkStream.listen((String? uriString) async {
    if (uriString != null &&
        uriString.toString().startsWith(redirectUrl.toString())) {
      completer.complete(Uri.parse(uriString));
      linksStreamSubscription?.cancel();
    }
  });

  return completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () {
      linksStreamSubscription?.cancel();
      throw TimeoutException(null);
    },
  );
}
