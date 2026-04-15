# المرحلة 16: الذكاء الاصطناعي المتكامل (AI Agent Pro)

## الأولوية: 🟡 متوسطة

## السياق
AI حالياً يعمل عبر REST API مع Gemini. يدعم المحادثة النصية و TTS (Wavenet + flutter_tts fallback).
لكنه **لا يقرأ بيانات حقيقية من قاعدة البيانات** و **Function Calling محدود** (فقط navigate_to يعمل فعلياً).

**الملفات المعنية:**
- `lib/services/ai_service.dart` — محرك Gemini REST API
- `lib/services/ai_chat_controller.dart` — إدارة المحادثة والصوت
- المفتاح: يُقرأ من `.env` عبر `dotenv.env['GOOGLE_API_KEY']`
- النموذج: `gemini-2.0-flash` (متغير `_modelId`)

## المهام

### 16.1 System Prompt ديناميكي
**ملف:** `lib/services/ai_service.dart`

بدلاً من system prompt ثابت، يتم بناؤه من بيانات حقيقية:

```dart
Future<String> _buildDynamicSystemPrompt() async {
  final db = await DatabaseHelper().database;
  
  final companies = await db.query('companies', limit: 1);
  final companyName = companies.isNotEmpty ? companies.first['name'] ?? 'شركتي' : 'شركتي';
  final currency = companies.isNotEmpty ? companies.first['currency'] ?? 'SAR' : 'SAR';
  final taxRate = companies.isNotEmpty ? companies.first['tax_rate'] ?? 15 : 15;
  
  final employeeCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM employees')) ?? 0;
  final invoiceCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM invoices')) ?? 0;
  final cashBalance = (await db.rawQuery("SELECT balance FROM accounts WHERE id = 'ACC_CASH'")).firstOrNull?['balance'] ?? 0;
  
  return '''
أنت "HBASSS Agent" — المساعد المالي الذكي لشركة "$companyName".
العملة: $currency | نسبة الضريبة: $taxRate%
عدد الموظفين: $employeeCount | عدد الفواتير: $invoiceCount
رصيد الخزينة: $cashBalance $currency

يمكنك تنفيذ:
- إنشاء فواتير وعروض أسعار وسندات
- استعلام عن أرصدة وتقارير
- إضافة موظفين ومنتجات
- التنقل بين الشاشات
- حساب الضرائب

ردودك مختصرة ومفيدة. تتحدث بلهجة عربية مهذبة.
عند تنفيذ أمر، استخدم الدوال المتاحة بدلاً من التخمين.
''';
}
```

### 16.2 توسيع Function Declarations
**ملف:** `lib/services/ai_service.dart`

في دالة `_buildRestFunctionDeclarations()` يجب إضافة:

```json
[
  {
    "name": "get_account_balance",
    "description": "الحصول على رصيد حساب معين",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "account_name": {"type": "STRING", "description": "اسم الحساب (مثل: الخزينة، البنك، المدينون)"}
      },
      "required": ["account_name"]
    }
  },
  {
    "name": "get_daily_sales",
    "description": "إجمالي مبيعات اليوم أو فترة محددة",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "date": {"type": "STRING", "description": "التاريخ بصيغة YYYY-MM-DD، أو 'today'"}
      }
    }
  },
  {
    "name": "get_employee_count",
    "description": "عدد الموظفين النشطين",
    "parameters": {"type": "OBJECT", "properties": {}}
  },
  {
    "name": "get_pending_invoices",
    "description": "الفواتير المعلقة غير المدفوعة",
    "parameters": {"type": "OBJECT", "properties": {}}
  },
  {
    "name": "create_invoice",
    "description": "إنشاء فاتورة مبيعات جديدة",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "client_name": {"type": "STRING"},
        "items": {"type": "STRING", "description": "أسماء الأصناف مفصولة بفاصلة"},
        "total": {"type": "NUMBER"}
      },
      "required": ["client_name", "total"]
    }
  },
  {
    "name": "check_stock",
    "description": "فحص كمية مخزون منتج",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "product_name": {"type": "STRING"}
      },
      "required": ["product_name"]
    }
  },
  {
    "name": "calculate_tax",
    "description": "حساب الضريبة على مبلغ",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "amount": {"type": "NUMBER"}
      },
      "required": ["amount"]
    }
  },
  {
    "name": "navigate_to",
    "description": "الانتقال لصفحة معينة",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "screen": {"type": "STRING", "description": "اسم الشاشة"}
      },
      "required": ["screen"]
    }
  }
]
```

### 16.3 تنفيذ Function Calls
**ملف:** `lib/services/ai_chat_controller.dart` أو `ai_service.dart`

إنشاء دالة `_executeFunctionCall`:
```dart
Future<String> _executeFunctionCall(String functionName, Map<String, dynamic> args) async {
  final db = await DatabaseHelper().database;
  
  switch (functionName) {
    case 'get_account_balance':
      final name = args['account_name'] ?? '';
      final result = await db.rawQuery(
        "SELECT balance FROM accounts WHERE name LIKE ?", ['%$name%']
      );
      if (result.isNotEmpty) {
        return "رصيد $name هو ${result.first['balance']}";
      }
      return "لم أجد حساب بهذا الاسم";
      
    case 'get_daily_sales':
      final today = DateTime.now().toIso8601String().split('T')[0];
      final result = await db.rawQuery(
        "SELECT SUM(total) as total FROM invoices WHERE issue_date LIKE ?", ['$today%']
      );
      return "إجمالي مبيعات اليوم: ${result.first['total'] ?? 0}";
      
    case 'get_employee_count':
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM employees')
      );
      return "عدد الموظفين: $count";
      
    case 'get_pending_invoices':
      final result = await db.rawQuery(
        "SELECT COUNT(*) as c, SUM(total) as t FROM invoices WHERE status != 'paid'"
      );
      return "الفواتير المعلقة: ${result.first['c']} فاتورة بإجمالي ${result.first['t'] ?? 0}";
      
    case 'check_stock':
      final name = args['product_name'] ?? '';
      final result = await db.rawQuery(
        "SELECT name, quantity FROM items WHERE name LIKE ?", ['%$name%']
      );
      if (result.isNotEmpty) {
        return "${result.first['name']}: الكمية المتوفرة ${result.first['quantity']}";
      }
      return "لم أجد منتج بهذا الاسم";
      
    case 'calculate_tax':
      final amount = (args['amount'] as num?)?.toDouble() ?? 0;
      final companies = await db.query('companies', limit: 1);
      final taxRate = (companies.firstOrNull?['tax_rate'] as num?)?.toDouble() ?? 15;
      final tax = amount * taxRate / 100;
      return "الضريبة ($taxRate%): $tax — الإجمالي: ${amount + tax}";
      
    case 'navigate_to':
      return "[NAVIGATE:${_mapScreenNameToIndex(args['screen'] ?? '')}]";
      
    default:
      return "لا أستطيع تنفيذ هذا الأمر حالياً";
  }
}
```

### 16.4 وضع أوفلاين
عند فشل الاتصال بـ Gemini API:
1. عرض رسالة واضحة: "أنت في وضع أوفلاين"
2. الأوامر التالية تعمل محلياً بدون API:
   - `[NAVIGATE:X]` — التنقل
   - الاستعلامات البسيطة من DB (get_balance, get_employee_count)
   - الحسابات (calculate_tax)

## معايير القبول
- [ ] "كم مبيعات اليوم؟" → يرد بالرقم الحقيقي من DB
- [ ] "كم عدد الموظفين؟" → العدد الحقيقي
- [ ] "كم رصيد الخزينة؟" → الرصيد الحقيقي
- [ ] "احسب ضريبة 10000" → الحساب الصحيح
- [ ] "روح للمخزون" → ينتقل فعلاً
- [ ] بدون إنترنت → رسالة واضحة + أوامر محلية تعمل
