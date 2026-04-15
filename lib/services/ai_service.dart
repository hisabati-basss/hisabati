import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'database_helper.dart';
import 'database_helper.dart';

abstract class AiBrainProvider {
  Future<String> processUserCommand(String command, {List<Map<String, dynamic>>? fileAttachments});
  Future<void> executeFunction(String functionName, Map<String, dynamic> arguments);
  void setUiActionCallback(Function(String, Map<String, dynamic>) callback);
}

class GeminiAiBrain implements AiBrainProvider {
  String _apiKey = '';
  Function(String, Map<String, dynamic>)? _onUiAction;
  
  // Manual history management for REST API
  static final List<Map<String, dynamic>> _history = [];

  GeminiAiBrain() {
    _apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
  }

  String getApiKey() => _apiKey;

  @override
  void setUiActionCallback(Function(String, Map<String, dynamic>) callback) {
    _onUiAction = callback;
  }

  @override
  Future<void> executeFunction(String functionName, Map<String, dynamic> arguments) async {
    await executeFunctionWithResult(functionName, arguments);
  }

  @override
  Future<String> processUserCommand(String command, {List<Map<String, dynamic>>? fileAttachments}) async {
    if (_apiKey.isEmpty) return "عذراً، لم يتم العثور على مفتاح Gemini في الإعدادات (.env).";

    List<Map<String, dynamic>> parts = [{"text": command}];
    if (fileAttachments != null) {
      for (var attachment in fileAttachments) {
        parts.add({
          "inline_data": {
            "mime_type": attachment["mime_type"],
            "data": attachment["data"]
          }
        });
      }
    }

    _history.add({"role": "user", "parts": parts});
    if (_history.length > 20) _history.removeRange(0, 2);

    try {
      return await _callGeminiRest();
    } catch (e) {
      debugPrint("REST Gemini Error: $e");
      rethrow; // Let the controller handle offline mode
    }
  }

  Future<String> _callGeminiRest({int retryCount = 0}) async {
    const model = "gemini-2.0-flash";
    final url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey";
    
    final systemPrompt = await _getDynamicSystemPromptText();
    
    final body = {
      "systemInstruction": {"parts": [{"text": systemPrompt}]},
      "contents": _history,
      "tools": [
        {
          "functionDeclarations": _buildRestFunctionDeclarations()
        }
      ],
      "generationConfig": {
        "temperature": 0.5,
        "maxOutputTokens": 1024,
      }
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Handle potential Function Calls in the internal rest call
      final candidate = data['candidates']?[0];
      final content = candidate?['content'];
      final parts = content?['parts'] as List?;
      
      if (parts != null) {
         String fullText = "";
         bool hasFunctionCall = false;
         
         for (var part in parts) {
            if (part.containsKey('functionCall')) {
               hasFunctionCall = true;
               final call = part['functionCall'];
               final name = call['name'];
               final args = call['args'] as Map<String, dynamic>;
               final result = await executeFunctionWithResult(name, args);
               
               _history.add({"role": "model", "parts": [part]});
               _history.add({
                 "role": "function", 
                 "parts": [{"functionResponse": {"name": name, "response": result}}]
               });
            } else if (part.containsKey('text')) {
               fullText += part['text'];
            }
         }
         
         if (hasFunctionCall) {
            return _callGeminiRest(retryCount: retryCount); // Recursive call internal with same retry state
         }
         
         if (fullText.isNotEmpty) {
            _history.add({"role": "model", "parts": [{"text": fullText}]});
            return fullText;
         }
      }
      return "تم تنفيذ طلبك بنجاح.";
    } else if (response.statusCode == 429 && retryCount < 5) {
      // Robust Backoff: 2, 5, 10, 15, 20 seconds
      final delays = [2, 5, 10, 15, 20];
      final delay = Duration(seconds: delays[retryCount]);
      debugPrint("ℹ️ Gemini Quota Notice (429): Retrying in ${delay.inSeconds}s... (Attempt ${retryCount + 1}/5)");
      await Future.delayed(delay);
      return _callGeminiRest(retryCount: retryCount + 1);
    } else {
      if (response.statusCode == 429) {
        debugPrint("ℹ️ Gemini Quota Fully Exhausted after 5 retries. Switching to Local Assistant Mode.");
      } else {
        debugPrint("❌ Gemini REST Error: ${response.statusCode} - ${response.body}");
      }
      throw Exception("API Error ${response.statusCode}");
    }
  }

  List<Map<String, dynamic>> _buildRestFunctionDeclarations() {
    return [
      {
        "name": "get_account_balance",
        "description": "معرفة رصيد حساب مالي محدد بالاسم (مثل: الخزينة، البنك، العميل أحمد).",
        "parameters": {
          "type": "OBJECT",
          "properties": {
            "account_name": {"type": "STRING", "description": "اسم الحساب أو الكلمة الدالة عليه"}
          },
          "required": ["account_name"]
        }
      },
      {
        "name": "get_daily_sales",
        "description": "الحصول على إجمالي مبيعات اليوم.",
        "parameters": {"type": "OBJECT", "properties": {}}
      },
      {
        "name": "get_employee_count",
        "description": "معرفة عدد الموظفين النشطين في الشركة.",
        "parameters": {"type": "OBJECT", "properties": {}}
      },
      {
        "name": "get_pending_invoices",
        "description": "معرفة عدد ومبالغ الفواتير المعلقة غير المدفوعة.",
        "parameters": {"type": "OBJECT", "properties": {}}
      },
      {
        "name": "check_stock",
        "description": "فحص كمية صنف معين في المخزن.",
        "parameters": {
          "type": "OBJECT",
          "properties": {
            "product_name": {"type": "STRING", "description": "اسم المنتج المراد فحصه"}
          },
          "required": ["product_name"]
        }
      },
      {
        "name": "calculate_tax",
        "description": "حساب ضريبة القيمة المضافة لمبلغ معين.",
        "parameters": {
          "type": "OBJECT",
          "properties": {
            "amount": {"type": "NUMBER", "description": "المبلغ المراد حساب ضريبته"}
          },
          "required": ["amount"]
        }
      },
      {
        "name": "navigate_to",
        "description": "الانتقال لشاشة محددة في التطبيق.",
        "parameters": {
          "type": "OBJECT",
          "properties": {
            "screen": {"type": "STRING", "description": "dashboard, invoices, reports, hr, inventory, settings, pos"}
          },
          "required": ["screen"]
        }
      }
    ];
  }

  Future<String> _getDynamicSystemPromptText() async {
    final db = DatabaseHelper();
    final company = await db.getCurrentCompanyContext();
    final currency = company['currency'] ?? 'SAR';
    final taxRate = company['tax_rate'] ?? 15;
    
    final employeeCount = (await db.getEmployees()).length;
    final todaySales = await db.getTodaySalesTotal();
    final cashBalance = await db.getAccountBalance('ACC_CASH');
    final pendingInvoices = await db.getPendingInvoicesStats();

    return """
أنت 'HBASSS' — المساعد المالي والتقني الذكي لشركة "${company['name'] ?? 'شركتي'}".
معلومات حالية للشركة:
- العملة الأساسية: $currency
- نسبة الضريبة: $taxRate%
- رصيد الخزينة: $cashBalance $currency
- مبيعات اليوم: $todaySales $currency
- عدد الموظفين: $employeeCount
- الفواتير المعلقة: ${pendingInvoices['count']} فاتورة بإجمالي ${pendingInvoices['total']} $currency

تعليماتك:
1. ردودك قصيرة، رسمية، وبلغة عربية مهذبة.
2. استخدم الأدوات المتاحة (Function Calling) بدلاً من التخمين عند السؤال عن بيانات.
3. إذا طلب المستخدم الانتقال لصفحة، استخدم `navigate_to`.
4. تعامل مع الأرقام بدقة محاسبية.
""";
  }

  Future<Map<String, dynamic>> executeFunctionWithResult(String functionName, Map<String, dynamic> arguments) async {
    final db = DatabaseHelper();
    
    try {
      switch (functionName) {
        case 'get_account_balance':
          final name = arguments['account_name'] ?? '';
          final result = await db.getAccountBalanceByName(name);
          if (result != null) {
            return {'status': 'success', 'account': result['name'], 'balance': result['balance']};
          }
          return {'status': 'error', 'message': 'لم يتم العثور على حساب بهذا الاسم'};

        case 'get_daily_sales':
          final total = await db.getTodaySalesTotal();
          return {'status': 'success', 'today_sales': total};

        case 'get_employee_count':
          final employees = await db.getEmployees();
          return {'status': 'success', 'count': employees.length};

        case 'get_pending_invoices':
          final stats = await db.getPendingInvoicesStats();
          return {'status': 'success', 'pending_count': stats['count'], 'pending_total': stats['total']};

        case 'check_stock':
          final name = arguments['product_name'] ?? '';
          final stock = await db.checkProductStock(name);
          if (stock != null) {
            return {
              'status': 'success', 
              'product': stock['name'], 
              'quantity': stock['quantity'], 
              'unit': stock['unit'] ?? 'قطعة'
            };
          }
          return {'status': 'error', 'message': 'الصنف غير موجود في المخزن'};

        case 'calculate_tax':
          final amount = (arguments['amount'] as num?)?.toDouble() ?? 0;
          final company = await db.getCurrentCompanyContext();
          final rate = (company['tax_rate'] as num?)?.toDouble() ?? 15.0;
          final tax = amount * (rate / 100);
          return {
            'status': 'success', 
            'amount': amount, 
            'tax_rate': rate, 
            'tax_amount': tax, 
            'total_with_tax': amount + tax
          };

        case 'navigate_to':
          if (_onUiAction != null) {
            _onUiAction!('navigate', {'screen': arguments['screen']});
          }
          return {'status': 'success', 'action': 'navigating to ${arguments['screen']}'};

        default:
          return {'error': 'Function not implemented'};
      }
    } catch (e) {
      return {'error': 'Internal processing error: $e'};
    }
  }
}
