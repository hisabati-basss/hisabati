import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyBLSAZ2ikgynDOaRPWkFs5BaegUQBmoqJM';

  // Simulate dynamically loaded settings
  double taxRate = 12.0; // Let's test non-14% to verify it works
  String currency = 'دينار كويتي';
  String country = 'الكويت';
  String industryType = 'مقاولات';
  
  final divisor = 1 + (taxRate / 100);

  final String systemPrompt = """
أنت 'HBASSS'، مدير مالي محاسبي ذكي للغاية وخبير في الضرائب والنظام التجاري العام.
تقع هذه الشركة في \$country ونشاطها هو \$industryType وتتعامل بعملة \$currency.
مهمتك استخراج المعلومات من كلام المستخدم وتحويلها بدقة عالية إلى أوامر حقيقية للنظام (Function Calls).

القواعد الحسابية والضريبية:
1. نسبة ضريبة القيمة المضافة الحالية للشركة هي \$taxRate%.
2. لا تستنتج أرقام من الخيال؛ يجب حساب الضريبة بدقة، للتقريب نستخدم منزلتين عشريتين.
3. إذا طُلب فاتورة بمبلغ "شامل الضريبة":
   - الإجمالي = المبلغ المطلوب
   - الأساس (قبل الضريبة) = المبلغ المطلوب / \$divisor
   - الضريبة = الإجمالي - الأساس
4. إذا طُلب فاتورة بمبلغ "غير شامل الضريبة":
   - الأساس = المبلغ المطلوب
   - الضريبة = المبلغ المطلوب * (\${taxRate / 100})
   - الإجمالي = الأساس + الضريبة
5. إذا طلب "طباعة الفاتورة" اجعل المتغير print_receipt = true.
6. إذا طلب مزامنة البيانات استخدم sync_data.

يمنع منعاً باتاً استنتاج أرقام غير موجودة، وكل المبالغ ستكون بعملة \$currency.
""";

  final tool = Tool(functionDeclarations: [
    FunctionDeclaration(
      'create_invoice',
      'ينشئ فاتورة جديدة للعميل بناءً على المبالغ المقدمة.',
      Schema(
        SchemaType.object,
        properties: {
          'client_name': Schema(SchemaType.string, description: 'اسم العميل الموجهة له الفاتورة.'),
          'subtotal': Schema(SchemaType.number, description: 'المبلغ الأساسي قبل الضريبة.'),
          'tax_amount': Schema(SchemaType.number, description: 'قيمة الضريبة.'),
          'total': Schema(SchemaType.number, description: 'المبلغ الإجمالي شامل الضريبة.'),
          'payment_status': Schema(SchemaType.string, description: 'حالة الدفع (paid أو unpaid).', nullable: true),
          'print_receipt': Schema(SchemaType.boolean, description: 'هل طلب المستخدم طباعة الفاتورة؟', nullable: true),
        },
        requiredProperties: ['client_name', 'subtotal', 'tax_amount', 'total'],
      ),
    ),
  ]);

  final model = GenerativeModel(
    model: 'gemini-1.5-pro-latest',
    apiKey: apiKey,
    systemInstruction: Content.system(systemPrompt),
    tools: [tool],
  );

  final chat = model.startChat();
  
  print('=====================================');
  print('Testing dynamic profile: \$country | \$currency | Tax: \$taxRate%');
  String userInput = "سجل فاتورة لعميل اسمه أحمد بـ 5000 دينار شاملة الضريبة، واطبع لي الإيصال ضروري";
  print('🎤 User command: \$userInput');
  print('=====================================');

  try {
    final response = await chat.sendMessage(Content.text(userInput));
    
    if (response.functionCalls.isNotEmpty) {
      final call = response.functionCalls.first;
      print('✅ AI successfully extracted a Function Call: \${call.name}');
      print('📦 Arguments extracted by AI:');
      
      call.args.forEach((key, value) {
        print('  - \$key: \$value');
      });
      
      print('=====================================');
      print('Executing Database Insert (Mock SQLite)...');
      print('Executing Supabase Upsert (Mock Sync)...');
    } else {
      print('❌ AI replied with text instead of a tool call:');
      print(response.text);
    }
  } catch (e) {
    print('Error: \$e');
  }
}
