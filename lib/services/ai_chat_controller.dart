import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/robot_avatar.dart';
import 'industry_provider.dart';
import 'ai_service.dart';
import 'database_helper.dart';

class Message {
  final String text;
  final bool isUser;
  final String? attachmentName;
  final bool isOffline;
  
  Message({
    required this.text, 
    required this.isUser, 
    this.attachmentName,
    this.isOffline = false,
  });
}

class AiChatController extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  String? _recordedFilePath;

  File? selectedFile;
  String? selectedFileName;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isThinking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isThinking => _isThinking;

  RobotState get robotState {
    if (_isThinking) return RobotState.thinking;
    if (_isListening) return RobotState.listening;
    if (_isSpeaking) return RobotState.speaking;
    return RobotState.idle;
  }

  final List<Message> messages = [];
  Function(int)? onNavigateRequested;
  Function(IndustryType)? onIndustryChanged;
  Function(String)? onReportRequested;

  // Dynamic Suggestions
  List<String> _currentSuggestions = ['شرح مميزات HBASSS', 'كيف أنشئ فاتورة؟', 'تحليل القوائم المالية'];
  List<String> get currentSuggestions => _currentSuggestions;

  // Chat history for context
  final List<Map<String, dynamic>> _chatHistory = [];

  AiChatController() {
    _initAudioPlayer();
    _initTts();
    _resetHistory();
  }

  void _resetHistory() {
    _chatHistory.clear();
    _chatHistory.add({
      "role": "user",
      "parts": [{"text": """أنت "HBASSS"، وكيل الذكاء الاصطناعي المالي (AI Agent) للحسابات. وظيفتك هي إدارة الحسابات والرد على كل ما يتعلق بالنظام بأسلوب احترافي وفخم.
تتحدث بلهجة خليجية/سعودية مهذبة.
أنت تدعم القطاعات التالية: (العقارات، المدارس، الفنادق، المستشفيات، المصانع، تأجير السيارات).

عند طلب تقرير، أجب بـ [REPORT:نوع_التقرير] (مثل: مبيعات، مشتريات، عملاء، ضرائب، ميزان_مراجعة).
عند الانتقال لصفحة أضف [NAVIGATE:رقم]:
0:لوحة التحكم، 1:الفواتير، 2:الضرائب، 3:الموارد البشرية، 4:التدقيق، 5:دراسة الجدوى، 6:المستخدمين، 7:التسويق، 8:الاشتراكات، 9:المخزون، 10:المشاريع، 13:الروبوت المركزي.

عند تغيير النشاط (مثلاً: أريد فتح حسابات لشركة عقارات)، أجب بـ [SET_INDUSTRY:النوع].
عند طلب مسح باركود، أجب بـ [SCAN_BARCODE].

أجب باختصار وذكاء."""}]
    });
    _chatHistory.add({
      "role": "model",
      "parts": [{"text": "أهلاً بك يا سيدي. أنا HBASSS، وكيلك المالي الذكي. كيف يمكنني خدمتك اليوم في الحسابات؟"}]
    });
  }

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void _initTts() async {
    try {
      await _flutterTts.setLanguage("ar-SA"); // Back to Saudi Arabic
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
    
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint("TTS Error handler: $msg");
    });
  }

  // ======== FILE PICKER ========
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      selectedFile = File(result.files.single.path!);
      selectedFileName = result.files.single.name;
      notifyListeners();
    }
  }

  void removeFile() {
    selectedFile = null;
    selectedFileName = null;
    notifyListeners();
  }

  void clearChat() {
    _resetHistory();
    messages.clear();
    messages.insert(0, Message(text: "تم مسح الذاكرة بنجاح. كيف يمكنني مساعدتك الآن؟", isUser: false));
    notifyListeners();
  }

  // ======== MICROPHONE ========
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopProcessing();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    await stopProcessing();
    bool hasPermission = false;
    try {
      hasPermission = await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint("Record Permission Error: $e");
    }
    if (hasPermission) {
      _isListening = true;
      notifyListeners();
      final dir = await getTemporaryDirectory();
      _recordedFilePath = '${dir.path}/temp_recording.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _recordedFilePath!,
      );
    } else {
      messages.insert(0, Message(text: "عذراً، لا يوجد صلاحية مايكروفون.", isUser: false));
      notifyListeners();
    }
  }

  Future<void> stopProcessing() async {
    if (_isListening) {
      _isListening = false;
      notifyListeners();
      _recordedFilePath = await _audioRecorder.stop();
      if (_recordedFilePath != null) {
        await _processAudio();
      }
    }
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
    }
    notifyListeners();
  }

  String? _lastCommand; // Store last sent command for manual retry
  bool isLastRequestFailed = false; // Track if last Gemini call failed

  // ======== SEND TEXT MESSAGE ========
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty && selectedFile == null) return;
    _lastCommand = text;
    isLastRequestFailed = false; // Reset on new command

    messages.insert(0, Message(
      text: text,
      isUser: true,
      attachmentName: selectedFileName,
    ));
    _isThinking = true;
    notifyListeners();

    // 🏆 STEP 1: Attempt Local/Offline Processing First (Free & Instant)
    final localResponse = await _handleLocalCommand(text);
    if (localResponse != null) {
      _isThinking = false;
      messages.insert(0, Message(
        text: localResponse, 
        isUser: false,
        isOffline: true
      ));
      notifyListeners();
      _playVoiceFromText(localResponse);
      return; // Stop here - Command handled locally
    }

    await _processWithGemini(text);
  }

  /// Manually retry the last sent command (useful if Gemini was rate-limited)
  Future<void> retryLastMessage() async {
    if (_lastCommand == null) return;
    isLastRequestFailed = false; // Reset on retry
    _isThinking = true;
    notifyListeners();
    await _processWithGemini(_lastCommand!);
  }

  Future<void> _processWithGemini(String text) async {
    // ☁️ Use Cloud AI (Gemini) for complex/unhandled queries
    List<Map<String, dynamic>> parts = [{"text": text}];

    if (selectedFile != null) {
      try {
        final bytes = await selectedFile!.readAsBytes();
        String ext = selectedFile!.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext == 'png') mimeType = 'image/png';
        if (ext == 'pdf') mimeType = 'application/pdf';

        parts.add({
          "inline_data": {
            "mime_type": mimeType,
            "data": base64Encode(bytes),
          }
        });
        parts.add({"text": "المستند المرفق أعلاه، حلله بالكامل واستخرج بياناته."});
      } catch (e) {
        debugPrint("File read error: $e");
      }
      selectedFile = null;
      selectedFileName = null;
    }

    final aiBrain = GeminiAiBrain();
    aiBrain.setUiActionCallback((action, params) {
      if (action == 'navigate') {
        final screen = params['screen'] as String;
        final index = _mapScreenToIndex(screen);
        if (onNavigateRequested != null) onNavigateRequested!(index);
      }
    });

    List<Map<String, dynamic>> attachments = [];
    if (parts.length > 1) {
      attachments.add({
        "mime_type": parts[1]["inline_data"]["mime_type"],
        "data": parts[1]["inline_data"]["data"]
      });
    }

    try {
      final responseText = await aiBrain.processUserCommand(text, fileAttachments: attachments.isNotEmpty ? attachments : null);
      _parseAndExecuteResponse(responseText);
      isLastRequestFailed = false; // Success
    } catch (e) {
      isLastRequestFailed = true; // Mark as failed
      final fallbackResponse = await _handleLocalCommand(text) ?? 
          "عذراً، نظام جيميناي مشغول حالياً. تم تفعيل المساعد المحلي. هل تود المحاولة مرة أخرى يدوياً؟";
      
      messages.insert(0, Message(
        text: fallbackResponse, 
        isUser: false,
        isOffline: true
      ));
      _playVoiceFromText(fallbackResponse);
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  /// 🤖 Local Expert Engine: Handles common ERP commands instantly without Cloud API
  Future<String?> _handleLocalCommand(String text) async {
    final db = DatabaseHelper();
    final lowerText = text.toLowerCase();

    // 1. Navigation Mapping
    int? targetIndex;
    String? screenName;

    if (lowerText.contains("مبيعات") || lowerText.contains("فواتير")) {
      targetIndex = _mapScreenToIndex('invoices');
      screenName = "الفواتير والمبيعات";
    } else if (lowerText.contains("بشرية") || lowerText.contains("موظف") || lowerText.contains("رواتب") || lowerText.contains("مؤظف")) {
      targetIndex = _mapScreenToIndex('hr');
      screenName = "الموارد البشرية";
    } else if (lowerText.contains("ضريبة") || lowerText.contains("ضرائب") || lowerText.contains("زكاة")) {
      targetIndex = _mapScreenToIndex('taxes');
      screenName = "الضرائب والزكاة";
    } else if (lowerText.contains("مخزن") || lowerText.contains("مخازن") || lowerText.contains("أصناف")) {
      targetIndex = _mapScreenToIndex('inventory');
      screenName = "المخازن والأصناف";
    } else if (lowerText.contains("تقارير") || lowerText.contains("أداء")) {
      targetIndex = _mapScreenToIndex('reports');
      screenName = "التقارير المالية";
    } else if (lowerText.contains("إعدادات") || lowerText.contains("تهيئ")) {
      targetIndex = _mapScreenToIndex('settings');
      screenName = "الإعدادات العامة";
    } else if (lowerText.contains("رئيسي") || lowerText.contains("لوحة")) {
      targetIndex = _mapScreenToIndex('dashboard');
      screenName = "لوحة التحكم";
    } else if (lowerText.contains("نقاط") || lowerText.contains("بيع")) {
      targetIndex = _mapScreenToIndex('pos');
      screenName = "نقاط البيع";
    }

    if (targetIndex != null) {
      if (onNavigateRequested != null) onNavigateRequested!(targetIndex);
      return "سأقوم بنقلك فوراً إلى $screenName.";
    }

    // 2. Common Greetings & Identity (Local)
    if (lowerText.contains("مرحبا") || lowerText.contains("أهلا") || lowerText.contains("سلام") || lowerText.contains("هلا")) {
      return "أهلاً بك يا سيدي. أنا HBASSS، وكيلك المالي الذكي. كيف يمكنني خدمتك اليوم؟";
    }
    
    if (lowerText.contains("من أنت") || lowerText.contains("اسمك") || lowerText.contains("مين انت")) {
      return "أنا HBASSS، الوكيل الذكي لنظام الحسابات. أعمل هنا لمساعدتك في إدارة أمورك المالية بسرعة وكفاءة.";
    }

    // 3. Data Lookup Patterns
    if (lowerText.contains("رصيد") || lowerText.contains("فلوس") || lowerText.contains("كاش")) {
      final cash = await db.getAccountBalance('ACC_CASH');
      return "رصيد الخزينة الحالي هو $cash (تم الجلب محلياً).";
    }
    
    if (lowerText.contains("مبيعات") && lowerText.contains("اليوم")) {
      final total = await db.getTodaySalesTotal();
      return "إجمالي مبيعات اليوم حتى الآن هو $total (تم الجلب محلياً).";
    }

    if (lowerText.contains("موظف") && (lowerText.contains("كم") || lowerText.contains("عدد"))) {
      final employees = await db.getEmployees();
      return "عدد الموظفين المسجلين حالياً هو ${employees.length} موظف.";
    }

    // 4. Simple Calculation Fallback
    if (lowerText.contains("احسب") && lowerText.contains("ضريبة")) {
      final numMatch = RegExp(r'\d+').firstMatch(text);
      if (numMatch != null) {
        final amount = double.parse(numMatch.group(0)!);
        final tax = amount * 0.15;
        return "الضريبة (15%) لمبلغ $amount هي $tax. الإجمالي: ${amount + tax}.";
      }
    }

    // 5. Reset Command
    if (lowerText.contains("مسح") || lowerText.contains("ذاكرة")) {
      clearChat();
      return "تم مسح ذاكرة الدردشة المحلية بنجاح.";
    }

    return null; 
  }

  int _mapScreenToIndex(String screen) {
    switch (screen.toLowerCase()) {
      case 'dashboard': return 1;
      case 'accounting': 
      case 'invoices': return 2;
      case 'taxes': return 3;
      case 'hr': return 4;
      case 'reports': return 9;
      case 'inventory': return 10;
      case 'projects': return 11;
      case 'settings': return 12;
      case 'assets': return 14;
      case 'pos': return 21;
      default: return 0;
    }
  }

  // ======== PROCESS AUDIO ========
  Future<void> _processAudio() async {
    messages.insert(0, Message(text: "🎤 مقطع صوتي مرسل", isUser: true));
    _isThinking = true;
    notifyListeners();

    final file = File(_recordedFilePath!);
    if (!await file.exists()) return;
    final audioBytes = await file.readAsBytes();


    final aiBrain = GeminiAiBrain();
    
    // Set UI actions callback for Phase 8
    aiBrain.setUiActionCallback((action, params) {
      if (action == 'navigate') {
        final screen = params['screen'] as String;
        final index = _mapScreenToIndex(screen);
        if (onNavigateRequested != null) {
          onNavigateRequested!(index);
        }
      }
    });

    List<Map<String, dynamic>> attachments = [
      {
        "mime_type": "audio/mp4",
        "data": base64Encode(audioBytes)
      }
    ];

    try {
      final responseText = await aiBrain.processUserCommand("استمع للمقطع الصوتي التالي ونفذ ما يطلبه المستخدم.", fileAttachments: attachments);
      _parseAndExecuteResponse(responseText);
    } catch (e) {
      _isThinking = false;
      messages.insert(0, Message(text: "عذراً واجهت مشكلة: $e", isUser: false));
      notifyListeners();
    }
  }


  // ======== PARSE AI RESPONSE ========
  void _parseAndExecuteResponse(String rawResponse) {
    _isThinking = false;
    String cleanText = rawResponse;

    // Extract [NAVIGATE:ID]
    final navMatch = RegExp(r'\[NAVIGATE:(\d+)\]').firstMatch(rawResponse);
    if (navMatch != null) {
      int screenId = int.tryParse(navMatch.group(1) ?? '0') ?? 0;
      cleanText = cleanText.replaceAll(navMatch.group(0)!, '').trim();
      if (onNavigateRequested != null) {
        _updateSuggestionsByScreen(screenId);
        Future.delayed(const Duration(milliseconds: 500), () {
          onNavigateRequested!(screenId);
        });
      }
    }

    // Extract [SET_INDUSTRY:TYPE]
    final indMatch = RegExp(r'\[SET_INDUSTRY:(\w+)\]').firstMatch(rawResponse);
    if (indMatch != null) {
      String typeStr = indMatch.group(1)?.toLowerCase() ?? '';
      cleanText = cleanText.replaceAll(indMatch.group(0)!, '').trim();
      IndustryType type = IndustryType.general;
      if (typeStr.contains('عقار')) type = IndustryType.realEstate;
      if (typeStr.contains('سيار')) type = IndustryType.carRental;
      if (typeStr.contains('مدر')) type = IndustryType.education;
      if (typeStr.contains('فندق')) type = IndustryType.hospitality;
      if (typeStr.contains('مصنع')) type = IndustryType.manufacturing;
      
      if (onIndustryChanged != null) {
        _updateSuggestionsByIndustry(type);
        onIndustryChanged!(type);
      }
    }

    // Extract [REPORT:TYPE]
    final repMatch = RegExp(r'\[REPORT:(\w+)\]').firstMatch(rawResponse);
    if (repMatch != null) {
      String repType = repMatch.group(1) ?? '';
      cleanText = cleanText.replaceAll(repMatch.group(0)!, '').trim();
      if (onReportRequested != null) {
        onReportRequested!(repType);
      }
    }

    messages.insert(0, Message(text: cleanText, isUser: false));
    notifyListeners();

    // Play TTS
    if (cleanText.isNotEmpty && cleanText.length < 250) {
      _playVoiceFromText(cleanText);
    }
  }

  // ======== TTS (Google Cloud TTS REST + flutter_tts fallback) ========
  Future<void> _playVoiceFromText(String text) async {
    if (text.trim().isEmpty) return;
    
    _isSpeaking = true;
    notifyListeners();

    // Cleanup text for better TTS reading
    String cleanTextForTts = text.replaceAll(RegExp(r'[*#_~`]'), '');
    
    // Use Local Native TTS (Free and Offline)
    try {
      await _flutterTts.setLanguage('ar-SA');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(cleanTextForTts);
    } catch (e) {
      debugPrint("⚠️ Local TTS failed: $e");
    } finally {
      // isSpeaking state is managed globally by TTS handlers (line 116-125)
    }
  }

  void _updateSuggestionsByScreen(int screenId) {
    switch (screenId) {
      case 1: // Invoices
         _currentSuggestions = ['إنشاء فاتورة ضريبية', 'البحث عن فاتورة قديمة', 'تقرير مبيعات الشهر'];
         break;
      case 2: // Taxes
         _currentSuggestions = ['إقرار القيمة المضافة', 'فحص الفواتير المعلقة', 'تحليل الوعاء الضريبي'];
         break;
      case 3: // HR
         _currentSuggestions = ['احتساب مسيرة الرواتب', 'إضافة موظف جديد', 'طلب إجازة'];
         break;
      case 9: // Inventory
         _currentSuggestions = ['جرد المخزن حالياً', 'تحويل بين المستودعات', 'الأصناف منتهية الصلاحية'];
         break;
      default:
         _currentSuggestions = ['توقعات الأرباح القادمة', 'تحليل التدفق النقدي', 'مراجعة الميزانية'];
    }
    notifyListeners();
  }

  void _updateSuggestionsByIndustry(IndustryType type) {
    switch (type) {
      case IndustryType.realEstate:
         _currentSuggestions = ['إضافة وحدة عقارية', 'تحصيل إيجار متأخر', 'تقرير العقود المنتهية'];
         break;
      case IndustryType.carRental:
         _currentSuggestions = ['تسجيل عقد تأجير', 'فحص السيارات المتوفرة', 'تنبيهات الصيانة'];
         break;
      case IndustryType.education:
         _currentSuggestions = ['تسجيل طالب جديد', 'سداد رسوم دراسية', 'غياب المعلمين'];
         break;
      default:
         break;
    }
    notifyListeners();
  }
}
