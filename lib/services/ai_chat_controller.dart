import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final GeminiAiBrain _aiBrain = GeminiAiBrain();
  
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

  AiChatController() {
    _initAudioPlayer();
    _initTts();
    _setupAiCallbacks();
  }

  void _setupAiCallbacks() {
    _aiBrain.setUiActionCallback((action, params) {
      if (action == 'navigate') {
        final screen = params['screen'] as String;
        final index = _mapScreenToIndex(screen);
        if (onNavigateRequested != null) {
          _updateSuggestionsByScreen(index);
          onNavigateRequested!(index);
        }
      }
    });
  }

  void clearChat() {
    _aiBrain.clearHistory();
    messages.clear();
    messages.insert(0, Message(text: "تم مسح الذاكرة بنجاح. كيف يمكنني مساعدتك الآن؟", isUser: false));
    notifyListeners();
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
      await _flutterTts.setLanguage("ar-SA");
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
  }

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

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopProcessing();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    await stopProcessing();
    bool hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      _isListening = true;
      notifyListeners();
      final dir = await getTemporaryDirectory();
      _recordedFilePath = '${dir.path}/temp_recording.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _recordedFilePath!,
      );
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

  String? _lastCommand;
  bool isLastRequestFailed = false;

  Future<void> sendTextMessage(String text) async {
    if (_isThinking) return;
    if (text.trim().isEmpty && selectedFile == null) return;
    _lastCommand = text;
    isLastRequestFailed = false;

    messages.insert(0, Message(
      text: text,
      isUser: true,
      attachmentName: selectedFileName,
    ));
    _isThinking = true;
    notifyListeners();

    await _processWithGemini(text);
  }

  Future<void> retryLastMessage() async {
    if (_lastCommand == null) return;
    isLastRequestFailed = false;
    _isThinking = true;
    notifyListeners();
    await _processWithGemini(_lastCommand!);
  }

  Future<void> _processWithGemini(String text) async {
    List<Map<String, dynamic>> attachments = [];
    if (selectedFile != null) {
      try {
        final bytes = await selectedFile!.readAsBytes();
        String ext = selectedFile!.path.split('.').last.toLowerCase();
        String mimeType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
        if (ext == 'png') mimeType = 'image/png';

        attachments.add({
          "mime_type": mimeType,
          "data": base64Encode(bytes),
        });
      } catch (e) {
        debugPrint("File read error: $e");
      }
      selectedFile = null;
      selectedFileName = null;
    }

    try {
      final responseText = await _aiBrain.processUserCommand(
        text, 
        fileAttachments: attachments.isNotEmpty ? attachments : null
      );
      _parseAndExecuteResponse(responseText);
      isLastRequestFailed = false;
    } catch (e) {
      isLastRequestFailed = true;
      final fallbackResponse = await _handleLocalCommand(text) ?? 
          "عذراً، نظام جيميناي غير متاح حالياً بسبب ضغط الطلبات. تم تفعيل المساعد المحلي المحدود لمساعدتك.";
      
      messages.insert(0, Message(text: fallbackResponse, isUser: false, isOffline: true));
      _playVoiceFromText(fallbackResponse);
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<String?> _handleLocalCommand(String text) async {
    final db = DatabaseHelper();
    final lowerText = text.toLowerCase();

    // 1. Navigation locally
    if (lowerText.contains("افتح") || lowerText.contains("اذهب") || lowerText.contains("شاشة")) {
      String? target;
      if (lowerText.contains("الرئيسية") || lowerText.contains("لوحة")) target = "dashboard";
      if (lowerText.contains("فاتورة") || lowerText.contains("فواتير")) target = "invoices";
      if (lowerText.contains("موظف") || lowerText.contains("عمال")) target = "hr";
      if (lowerText.contains("مخزن") || lowerText.contains("منتج")) target = "inventory";
      if (lowerText.contains("إعدادات")) target = "settings";
      if (lowerText.contains("نقطة") || lowerText.contains("كاشير")) target = "pos";

      if (target != null) {
        final index = _mapScreenToIndex(target);
        if (onNavigateRequested != null) onNavigateRequested!(index);
        return "جاري الانتقال لـ ${tr('sidebar.' + target)} (محلياً).";
      }
    }

    // 2. Financials
    if (lowerText.contains("رصيد") || lowerText.contains("كاش") || lowerText.contains("خزينة")) {
      final cash = await db.getAccountBalance('ACC_CASH');
      return "رصيد الخزينة الحالي هو $cash (تم الجلب محلياً).";
    }
    
    if (lowerText.contains("مبيعات") && (lowerText.contains("اليوم") || lowerText.contains("الآن"))) {
      final total = await db.getTodaySalesTotal();
      return "إجمالي مبيعات اليوم حتى الآن هو $total (تم الجلب محلياً).";
    }

    // 3. HR
    if (lowerText.contains("موظف") || lowerText.contains("عامل")) {
      final count = (await db.getEmployees()).length;
      return "يوجد حالياً $count موظف مسجل في النظام (محلياً).";
    }

    // 4. Invoices
    if (lowerText.contains("فاتورة") || lowerText.contains("فواتير")) {
      final stats = await db.getPendingInvoicesStats();
      return "يوجد ${stats['count']} فاتورة معلقة بإجمالي ${stats['total']} (محلياً).";
    }

    return null; 
  }

  int _mapScreenToIndex(String screen) {
    switch (screen.toLowerCase()) {
      case 'dashboard': return 1;
      case 'invoices': return 2;
      case 'taxes': return 3;
      case 'hr': return 4;
      case 'inventory': return 10;
      case 'pos': return 21;
      default: return 0;
    }
  }

  Future<void> _processAudio() async {
    messages.insert(0, Message(text: "🎤 مقطع صوتي مرسل", isUser: true));
    _isThinking = true;
    notifyListeners();

    final file = File(_recordedFilePath!);
    if (!await file.exists()) return;
    final audioBytes = await file.readAsBytes();

    List<Map<String, dynamic>> attachments = [
      {
        "mime_type": "audio/mp4",
        "data": base64Encode(audioBytes)
      }
    ];

    try {
      final responseText = await _aiBrain.processUserCommand("استمع للمقطع الصوتي ونفذ الطلب.", fileAttachments: attachments);
      _parseAndExecuteResponse(responseText);
    } catch (e) {
      _isThinking = false;
      messages.insert(0, Message(text: "عذراً واجهت مشكلة: $e", isUser: false));
      notifyListeners();
    }
  }

  void _parseAndExecuteResponse(String rawResponse) {
    _isThinking = false;
    messages.insert(0, Message(text: rawResponse, isUser: false));
    notifyListeners();
    _playVoiceFromText(rawResponse);
  }

  Future<void> _playVoiceFromText(String text) async {
    if (text.trim().isEmpty) return;
    String cleanText = text.replaceAll(RegExp(r'[*#_~`]'), '');
    await _flutterTts.speak(cleanText);
  }

  void _updateSuggestionsByScreen(int index) {
    // Basic logic to update suggestions based on current context
    notifyListeners();
  }
}
