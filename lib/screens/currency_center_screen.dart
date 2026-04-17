import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/database_helper.dart';
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
      final response = await _db.fetchLiveRates(); // I'll add this to DatabaseHelper or a new service
      if (response != null) {
        for (var entry in response.entries) {
          await _db.addCurrencyRate({
            'from_currency': 'USD',
            'to_currency': entry.key,
            'rate': entry.value,
          });
        }
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildQuickConverter(context),
                const SizedBox(height: 32),
                Text(
                  tr('currency.last_update'),
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRateDialog,
        backgroundColor: primaryOrange,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          tr('currency.add_rate'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: context.textColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('currency.title'),
              style: TextStyle(
                color: context.textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              tr('currency.subtitle'),
              style: TextStyle(
                color: context.mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          IconButton(
            onPressed: _syncRatesFromApi,
            icon: const Icon(Icons.sync),
            color: const Color(0xFFFF9800),
            tooltip: 'تحديث الأسعار المباشرة',
          ),
      ],
    );
  }

  Widget _buildQuickConverter(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.4),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updateConversion(),
                      style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: context.mutedText.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _fromCurrency,
                      underline: Container(),
                      dropdownColor: Colors.black87,
                      items: ['USD', 'EUR', 'GBP', 'SAR', 'EGP', 'KWD', 'AED']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.textColor))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _fromCurrency = v!);
                        _updateConversion();
                      },
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Icon(Icons.swap_vert, color: Colors.orangeAccent),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _convertedResult.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _toCurrency,
                      underline: Container(),
                      dropdownColor: Colors.black87,
                      items: ['SAR', 'EGP', 'KWD', 'AED', 'USD', 'EUR', 'GBP']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: context.textColor))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _toCurrency = v!);
                        _updateConversion();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatesList() {
    return ListView.separated(
      itemCount: _rates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rate = _rates[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorder.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.currency_exchange, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rate['from_currency']} → ${rate['to_currency']}',
                      style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(rate['date'])),
                      style: TextStyle(color: context.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                rate['rate'].toString(),
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
