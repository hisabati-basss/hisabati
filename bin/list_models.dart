import 'package:http/http.dart' as http;

void main() async {
  const String apiKey = "AIzaSyCoZzzJVulnaRzrpLB8quFSzb4vpv33Phw";
  final url = Uri.parse("https://generativelanguage.googleapis.com/v1/models?key=$apiKey");
  
  try {
    final response = await http.get(url);
    print(response.body);
  } catch (e) {
    print(e);
  }
}
