# المرحلة 8: الذكاء الاصطناعي المتكامل

## الأولوية: 🟡 متوسطة

## السياق
AI حالياً يدعم:
- ✅ محادثة نصية مع Gemini
- ✅ تسجيل صوتي (Speech-to-Text)
- ✅ نطق الردود (TTS via ElevenLabs)
- ✅ Function Calling بسيط (create_invoice, sync_data)
- ✅ تحليل ملفات PDF/صور
- ❌ قراءة بيانات حقيقية من DB
- ❌ تنفيذ أوامر متنوعة
- ❌ وضع أوفلاين
- ❌ دعم Desktop كامل للصوت

## المهام

### 8.1 توسيع Function Declarations
**ملف:** `lib/services/ai_service.dart`

إضافة الدوال التالية لـ Gemini Function Calling:

```dart
// === المحاسبة ===
FunctionDeclaration('create_invoice', 'إنشاء فاتورة مبيعات جديدة', {
  'client_name': Schema.string, 'items': Schema.array, 'payment_type': Schema.string
}),
FunctionDeclaration('create_purchase_invoice', 'إنشاء فاتورة مشتريات', {
  'supplier_name': Schema.string, 'items': Schema.array
}),
FunctionDeclaration('create_quotation', 'إنشاء عرض سعر', {
  'client_name': Schema.string, 'items': Schema.array, 'validity_days': Schema.integer
}),
FunctionDeclaration('create_journal_entry', 'إنشاء قيد يومية', {
  'description': Schema.string, 'debit_account': Schema.string, 
  'credit_account': Schema.string, 'amount': Schema.number
}),
FunctionDeclaration('create_receipt_voucher', 'إنشاء سند قبض', {
  'client_name': Schema.string, 'amount': Schema.number, 'method': Schema.string
}),
FunctionDeclaration('create_payment_voucher', 'إنشاء سند صرف', {
  'supplier_name': Schema.string, 'amount': Schema.number
}),

// === الموارد البشرية ===
FunctionDeclaration('add_employee', 'إضافة موظف جديد', {
  'name': Schema.string, 'job_title': Schema.string, 'salary': Schema.number
}),
FunctionDeclaration('process_payroll', 'معالجة رواتب الشهر', {
  'month': Schema.string
}),
FunctionDeclaration('record_attendance', 'تسجيل حضور/انصراف', {
  'employee_name': Schema.string, 'type': Schema.string
}),
FunctionDeclaration('submit_leave_request', 'طلب إجازة', {
  'employee_name': Schema.string, 'start_date': Schema.string, 'days': Schema.integer
}),

// === المخزون ===
FunctionDeclaration('add_product', 'إضافة منتج جديد', {
  'name': Schema.string, 'price': Schema.number, 'quantity': Schema.integer
}),
FunctionDeclaration('check_stock', 'فحص مخزون منتج', {
  'product_name': Schema.string
}),
FunctionDeclaration('adjust_stock', 'تعديل كمية المخزون', {
  'product_name': Schema.string, 'new_quantity': Schema.integer
}),

// === التقارير ===
FunctionDeclaration('get_balance', 'الحصول على رصيد حساب', {
  'account_name': Schema.string
}),
FunctionDeclaration('get_daily_sales', 'مبيعات اليوم/الفترة', {
  'date': Schema.string
}),
FunctionDeclaration('get_pending_invoices', 'الفواتير المعلقة', {}),
FunctionDeclaration('get_employee_count', 'عدد الموظفين النشطيين', {}),
FunctionDeclaration('generate_report', 'إنشاء تقرير', {
  'type': Schema.string // profit_loss, balance_sheet, trial_balance, aging
}),

// === النظام ===
FunctionDeclaration('navigate_to', 'الانتقال لصفحة', {
  'screen': Schema.string
}),
FunctionDeclaration('backup_database', 'نسخ احتياطي', {}),
FunctionDeclaration('calculate_tax', 'حساب الضريبة', {
  'amount': Schema.number
}),
```

### 8.2 تنفيذ الدوال (Function Execution)
**ملف:** `lib/services/ai_chat_controller.dart`

- [ ] إنشاء `_executeFunctionCall(String name, Map params)` يربط كل دالة بالخدمة المناسبة
- [ ] إرجاع نتيجة التنفيذ لـ Gemini ليصوغها كرد عربي

### 8.3 System Prompt ديناميكي
**ملف:** `lib/services/ai_service.dart`

بدلاً من system prompt ثابت، يتم بناؤه ديناميكياً:

```dart
String _buildSystemPrompt() async {
  final company = await _db.getCurrentCompanyContext();
  final employeeCount = (await _db.getEmployees()).length;
  final todaySales = await _db.getTodaySalesTotal();
  final cashBalance = await _db.getAccountBalance('ACC_CASH');
  
  return '''
أنت HBASSS Agent - مساعد ذكي لشركة "${company['name']}"
العملة: ${company['currency']} | الضريبة: ${company['tax_rate']}%
عدد الموظفين: $employeeCount | مبيعات اليوم: $todaySales
رصيد الخزينة: $cashBalance

أنت تفهم العربية والإنجليزية. ردودك مختصرة ومفيدة.
يمكنك تنفيذ: فواتير، قيود، رواتب، مخزون، تقارير، وأكثر.
عند السؤال عن بيانات، استخدم الدوال المتاحة بدلاً من التخمين.
''';
}
```

### 8.4 وضع أوفلاين
- [ ] عند فقدان الاتصال، عرض رسالة واضحة
- [ ] أوامر أساسية تعمل محلياً بدون API:
  - الانتقال بين الصفحات
  - عرض الأرصدة من DB
  - حسابات بسيطة
- [ ] تخزين الأسئلة المعلقة وإرسالها عند عودة الاتصال

### 8.5 إصلاح TTS لسطح المكتب
- [ ] على Desktop: استخدام `flutter_tts` مع edge-tts engine (مجاني)
- [ ] ElevenLabs كـ premium option فقط
- [ ] خيار إيقاف الصوت نهائياً في الإعدادات

### 8.6 إصلاح التسجيل الصوتي لسطح المكتب
- [ ] استخدام `record` package مع fallback لـ Desktop
- [ ] أو استخدام TextField بدلاً من الميكروفون على Desktop
- [ ] زر ميكروفون يختفي إذا المنصة لا تدعم التسجيل

## معايير القبول
- [ ] "كم مبيعات اليوم؟" → يرد بالرقم الحقيقي من DB
- [ ] "أنشئ فاتورة لأحمد بـ 5000 ريال" → تنشأ فعلاً
- [ ] "كم موظف عندنا؟" → العدد الحقيقي
- [ ] "روح لصفحة المخزون" → ينتقل فعلاً
- [ ] بدون إنترنت → رسالة واضحة + أوامر أساسية تعمل
- [ ] TTS يعمل على Windows بدون crash
