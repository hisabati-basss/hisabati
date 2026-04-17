import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class GmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      debugPrint("Gmail Sign In Error: $e");
      return false;
    }
  }

  Future<List<File>> fetchInvoiceAttachments() async {
    if (_currentUser == null) return [];

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final gmailApi = GmailApi(httpClient);

    // List messages with attachments that look like invoices
    final query = "has:attachment (filename:pdf OR filename:jpg OR filename:png) (فاتورة OR invoice OR bill OR receipt)";
    final ListMessagesResponse results = await gmailApi.users.messages.list("me", q: query);

    List<File> downloadedFiles = [];
    final tempDir = await getTemporaryDirectory();

    if (results.messages != null) {
      for (var msg in results.messages!.take(5)) { // Limit to 5 for now
        final message = await gmailApi.users.messages.get("me", msg.id!);
        final payload = message.payload;
        if (payload?.parts == null) continue;

        for (var part in payload!.parts!) {
          if (part.filename != null && part.filename!.isNotEmpty) {
             final attachmentId = part.body!.attachmentId;
             if (attachmentId != null) {
                final attachment = await gmailApi.users.messages.attachments.get("me", msg.id!, attachmentId);
                // Decode from Base64
                if (attachment.data != null) {
                  final bytes = base64Url.decode(attachment.data!);
                  final file = File(p.join(tempDir.path, "gmail_${msg.id}_${part.filename}"));
                  await file.writeAsBytes(bytes);
                  downloadedFiles.add(file);
                }
             }
          }
        }
      }
    }
    return downloadedFiles;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }
}

