import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../theme/app_theme_extension.dart';

class CurrencyCenterScreen extends StatefulWidget {
  const CurrencyCenterScreen({super.key});

  @override
  State<CurrencyCenterScreen> createState() => _CurrencyCenterScreenState();
}

class _CurrencyCenterScreenState extends State<CurrencyCenterScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _rates = [];
  bool _isLoading = true;

  // Converter state
  final _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'USD';
  String _toCurrency = 'SAR';
  double _convertedResult = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rates = await _db.getCurrencyRates();
    setState(() {
      _rates = rates;
      _isLoading = false;
    });
    _updateConversion();
  }

  Future<void> _syncRatesFromApi() async {
    setState(() => _isLoading = true);
    try {
      final updatedRates = await CurrencyService().updateRatesOnline();
      for (var entry in updatedRates.entries) {
        await _db.addCurrencyRate({
          'from_currency': 'USD',
          'to_currency': entry.key,
          'rate': entry.value,
        });
      }
      await _loadData();
    } catch (e) {
      debugPrint("API Sync Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateConversion() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    // Find rate
    final rateEntry = _rates.firstWhere(
      (r) => r['from_currency'] == _fromCurrency && r['to_currency'] == _toCurrency,
      orElse: () => {'rate': 1.0},
    );
    double rate = (rateEntry['rate'] as num).toDouble();
    setState(() {
      _convertedResult = amount * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryOrange = const Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildQuickConverter(context),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      tr('currency.last_update'),
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _rates.isEmpty
                          ? _buildEmptyState()
                          : _buildRatesList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          elevation: 4,
          onPressed: _showAddRateDialog,
          backgroundColor: primaryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add, color: Colors.black, size: 20),
          label: Text(
            tr('currency.add_rate'),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.currency_exchange_outlined, color: Colors.orangeAccent, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('currency.title'),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              tr('currency.subtitle'),
              style: TextStyle(color: context.mutedText, fontSize: 10),
            ),
          ],
        ),
        const Spacer(),
        if (_isLoading)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          IconButton(
            constraints: const BoxConstraints(maxHeight: 32, maxWidth: 32),
            padding: EdgeInsets.zero,
            onPressed: _syncRatesFromApi,
            icon: const Icon(Icons.sync, size: 18),
            color: const Color(0xFFFF9800),
          ),
      ],
    );
  }

  Widget _buildQuickConverter(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.9),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                  _buildConverterRow(
                    controller: _amountController,
                    currency: _fromCurrency,
                    onCurrencyChanged: (v) {
                      setState(() => _fromCurrency = v!);
                      _updateConversion();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_vert, color: Colors.orangeAccent, size: 16),
                    ),
                  ),
                  _buildConverterRow(
                    result: _convertedResult.toStringAsFixed(2),
                    currency: _toCurrency,
                    isResult: true,
                    onCurrencyChanged: (v) {
                      setState(() => _toCurrency = v!);
                      _updateConversion();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildConverterRow({
    TextEditingController? controller,
    String? result,
    required String currency,
    required ValueChanged<String?> onCurrencyChanged,
    bool isResult = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: isResult
              ? Text(
                  result!,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, 
                    fontSize: 18, fontWeight: FontWeight.bold),
                )
              : TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _updateConversion(),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, 
                    fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                  ),
                ),
        ),
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: currency,
            underline: Container(),
            dropdownColor: Colors.grey.shade900,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white60),
            items: ['USD', 'EUR', 'GBP', 'SAR', 'EGP', 'KWD', 'AED']
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 13))))
                .toList(),
            onChanged: onCurrencyChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRatesList() {
    return ListView.separated(
      itemCount: _rates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rate = _rates[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.white, // Clean white in light mode
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_exchange, color: Colors.orangeAccent, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rate['from_currency']} → ${rate['to_currency']}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, 
                        fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(rate['date'])),
                      style: TextStyle(color: context.mutedText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                rate['rate'].toString(),
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _deleteRate(rate['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: context.mutedText.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            tr('currency.no_rates'),
            style: TextStyle(color: context.mutedText),
          ),
        ],
      ),
    );
  }

  void _showAddRateDialog() {
    String from = 'USD';
    String to = 'SAR';
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr('currency.add_rate')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: from,
                      items: ['USD', 'EUR', 'GBP', 'SAR', 'EGP', 'KWD', 'AED']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => from = v!),
                      decoration: InputDecoration(labelText: tr('currency.from')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: to,
                      items: ['SAR', 'EGP', 'KWD', 'AED', 'USD', 'EUR', 'GBP']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => to = v!),
                      decoration: InputDecoration(labelText: tr('currency.to')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr('currency.rate'),
                  hintText: 'e.g. 3.75',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common.cancel'))),
            ElevatedButton(
              onPressed: () async {
                double? r = double.tryParse(rateController.text);
                if (r != null) {
                  await _db.addCurrencyRate({
                    'from_currency': from,
                    'to_currency': to,
                    'rate': r,
                  });
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRate(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('common.details')),
        content: Text(tr('currency.delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _db.deleteCurrencyRate(id);
      _loadData();
    }
  }
}
