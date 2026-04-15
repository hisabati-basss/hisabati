import "package:http/http.dart" as http;
import "dart:convert";

void main() async {
  final key = "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";
  final url = "https://openrouter.ai/api/v1/chat/completions";
  
  final body = jsonEncode({
    "models": [
      "meta-llama/llama-3.3-70b-instruct:free",
      "google/gemma-3-27b-it:free",
      "qwen/qwen3.6-plus-preview:free"
    ],
    "messages": [
      {"role": "user", "content": "?????"}
    ]
  });

  var res = await http.post(Uri.parse(url), headers: {
    "Authorization": "Bearer $key",
    "Content-Type": "application/json"
  }, body: body);
  print(res.statusCode);
  if (res.statusCode == 200) {
    print(jsonDecode(res.body)["choices"][0]["message"]["content"]);
  } else {
    print(res.body);
  }
}
