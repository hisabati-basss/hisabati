import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  final auth = Supabase.instance.client.auth;
  // This will try to open Google login. We want to see if we can intercept the URL.
  // await auth.signInWithOAuth(OAuthProvider.google);
}
