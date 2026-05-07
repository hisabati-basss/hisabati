import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CurrencyService {
  // Base rates relative to 1 USD (Reference rates for offline use)
  static Map<String, double> baseRatesUSD = {
    'SAR': 3.75,
    'AED': 3.67,
    'EGP': 50.5,
    'KWD': 0.31,
    'JOD': 0.71,
    'BHD': 0.376,
    'OMR': 0.385,
    'QAR': 3.64,
    'LBP': 89500.0,
    'IQD': 1310.0,
    'LYD': 4.85,
    'SDG': 601.0,
    'TND': 3.12,
    'MAD': 10.05,
    'DZD': 134.5,
    'TRY': 36.5,
    'USD': 1.0,
    'GBP': 0.79,
    'EUR': 0.92,
    'INR': 84.5,
  };

  // Currency Symbols Mapping
  static const Map<String, String> currencySymbols = {
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'EGP': 'ج.م',
    'KWD': 'د.ك',
    'JOD': 'د.أ',
    'BHD': 'د.ب',
    'OMR': 'ر.ع',
    'QAR': 'ر.ق',
    'LBP': 'ل.ل',
    'IQD': 'ع.د',
    'LYD': 'ل.د',
    'SDG': 'ج.س',
    'TND': 'د.ت',
    'MAD': 'د.م',
    'DZD': 'د.ج',
    'TRY': '₺',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'INR': '₹',
  };

  /// Converts an amount from one currency to another using base USD rates.
  static double convert(double amount, String from, String to) {
    if (from == to) return amount;
    
    final fromRate = baseRatesUSD[from.toUpperCase()];
    final toRate = baseRatesUSD[to.toUpperCase()];
    
    if (fromRate == null || toRate == null) return amount;
    
    final amountInUSD = amount / fromRate;
    return amountInUSD * toRate;
  }

  /// Returns the symbol for the given currency code
  static String getSymbol(String code) {
    return currencySymbols[code.toUpperCase()] ?? code.toUpperCase();
  }

  /// Formats the amount for display
  static String format(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    final formatter = NumberFormat("#,##0.00", "en_US");
    return "${formatter.format(amount)} $symbol";
  }

  /// PRO VISION: Online Sync with ExchangeRate-API
  Future<Map<String, double>> updateRatesOnline() async {
    try {
      debugPrint("CurrencyService: Syncing with live exchange rates...");
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];
        
        // Update our baseRatesUSD map with live values
        rates.forEach((key, value) {
          if (baseRatesUSD.containsKey(key)) {
            baseRatesUSD[key] = (value as num).toDouble();
          }
        });
        
        debugPrint("CurrencyService: Successfully updated ${rates.length} rates.");
        return baseRatesUSD;
      }
    } catch (e) {
      debugPrint("CurrencyService Error: Failed to update rates: $e");
    }
    
    return baseRatesUSD;
  }
}

