class TaxConfig {
  final String countryCode;
  final String taxName; // VAT, GST, KDV, etc
  final double standardRate;
  final List<Map<String, dynamic>>? incomeTaxBrackets; // For countries with income tax
  final bool hasEInvoicing; // Electronic invoicing flag
  final String? eInvoiceProvider; // ZATCA, ETA, FTA, etc
  final bool isStateLevel; // For US system
  final Map<String, double> specialRates; // zero-rated, exempt items

  const TaxConfig({
    required this.countryCode,
    required this.taxName,
    required this.standardRate,
    this.incomeTaxBrackets,
    this.hasEInvoicing = false,
    this.eInvoiceProvider,
    this.specialRates = const {},
    this.isStateLevel = false,
  });
}

class TaxEngine {
  // Pre-configured Tax Models for 20+ countries
  static const Map<String, TaxConfig> globalTaxConfigs = {
    'Saudi Arabia': TaxConfig(
      countryCode: 'SA',
      taxName: 'VAT',
      standardRate: 15.0,
      hasEInvoicing: true,
      eInvoiceProvider: 'ZATCA',
      specialRates: {'Export': 0.0, 'Healthcare': 0.0, 'RealEstate': 5.0},
    ),
    'UAE': TaxConfig(
      countryCode: 'AE',
      taxName: 'VAT',
      standardRate: 5.0,
      hasEInvoicing: true,
      eInvoiceProvider: 'FTA',
      specialRates: {'Education': 0.0, 'Healthcare': 0.0},
    ),
    'Egypt': TaxConfig(
      countryCode: 'EG',
      taxName: 'VAT',
      standardRate: 14.0,
      hasEInvoicing: true,
      eInvoiceProvider: 'ETA',
      specialRates: {'Machinery': 5.0},
    ),
    'Jordan': TaxConfig(
      countryCode: 'JO',
      taxName: 'GST',
      standardRate: 16.0,
      specialRates: {'BasicFood': 4.0},
    ),
    'Kuwait': TaxConfig(
      countryCode: 'KW',
      taxName: 'None',
      standardRate: 0.0,
    ),
    'Bahrain': TaxConfig(
      countryCode: 'BH',
      taxName: 'VAT',
      standardRate: 10.0,
    ),
    'Oman': TaxConfig(
      countryCode: 'OM',
      taxName: 'VAT',
      standardRate: 5.0,
    ),
    'Qatar': TaxConfig(
      countryCode: 'QA',
      taxName: 'None',
      standardRate: 0.0,
    ),
    'Turkey': TaxConfig(
      countryCode: 'TR',
      taxName: 'KDV',
      standardRate: 20.0,
      hasEInvoicing: true,
      eInvoiceProvider: 'GIB',
      specialRates: {'BasicFood': 1.0, 'Textile': 10.0},
    ),
    'USA': TaxConfig(
      countryCode: 'US',
      taxName: 'Sales Tax',
      standardRate: 0.0,
      isStateLevel: true,
    ),
    'UK': TaxConfig(
      countryCode: 'GB',
      taxName: 'VAT',
      standardRate: 20.0,
      hasEInvoicing: true,
      eInvoiceProvider: 'HMRC',
    ),
    'Germany': TaxConfig(
      countryCode: 'DE',
      taxName: 'MwSt',
      standardRate: 19.0,
    ),
    'France': TaxConfig(
      countryCode: 'FR',
      taxName: 'TVA',
      standardRate: 20.0,
    ),
    'Italy': TaxConfig(
      countryCode: 'IT',
      taxName: 'IVA',
      standardRate: 22.0,
    ),
    'India': TaxConfig(
      countryCode: 'IN',
      taxName: 'GST',
      standardRate: 18.0,
    ),
    'Lebanon': TaxConfig(
      countryCode: 'LB',
      taxName: 'VAT',
      standardRate: 11.0,
    ),
    'Morocco': TaxConfig(
      countryCode: 'MA',
      taxName: 'TVA',
      standardRate: 20.0,
    ),
    'Algeria': TaxConfig(
      countryCode: 'DZ',
      taxName: 'TVA',
      standardRate: 19.0,
    ),
    'Tunisia': TaxConfig(
      countryCode: 'TN',
      taxName: 'TVA',
      standardRate: 19.0,
    ),
    'Libya': TaxConfig(
      countryCode: 'LY',
      taxName: 'None',
      standardRate: 0.0,
    ),
    'Iraq': TaxConfig(
      countryCode: 'IQ',
      taxName: 'Sales Tax',
      standardRate: 0.0,
    ),
  };

  /// Fetch standard config for a specific country
  static TaxConfig getConfigForCountry(String countryName) {
    if (globalTaxConfigs.containsKey(countryName)) {
      return globalTaxConfigs[countryName]!;
    }
    // Fallback default config if country isn't explicitly mapped
    return TaxConfig(
      countryCode: 'UNKNOWN',
      taxName: 'VAT',
      standardRate: 0.0, 
    );
  }

  /// Calculates the tax amount taking into consideration any specialized rates.
  static double calculateTax(double amount, String countryName, {String? itemCategory}) {
    final config = getConfigForCountry(countryName);
    
    // Check for special reduced/zero rates first
    if (itemCategory != null && config.specialRates.containsKey(itemCategory)) {
      return amount * (config.specialRates[itemCategory]! / 100);
    }
    
    // Default to Standard Rate
    return amount * (config.standardRate / 100);
  }

  /// Basic Tax/VAT Number validation
  static bool validateTaxNumber(String number, String countryName) {
    final config = getConfigForCountry(countryName);
    
    if (number.isEmpty) return false;

    // VERY basic regex checks based on country
    switch (config.countryCode) {
      case 'SA': // ZATCA: exactly 15 digits starting and ending with 3
        return RegExp(r'^3\d{13}3$').hasMatch(number);
      case 'AE': // FTA: exactly 15 digits
        return RegExp(r'^\d{15}$').hasMatch(number);
      case 'EG': // ETA: 9 digits
        return RegExp(r'^\d{9}$').hasMatch(number);
      case 'TR': // VKNO / TCNO
        return number.length == 10 || number.length == 11;
      case 'GB': // GB VAT: 9 digits
        return RegExp(r'^\d{9}$').hasMatch(number);
      default:
        // Generic fallback: Minimum 5 alphanumeric characters
        return number.length >= 5; 
    }
  }

  /// Generates invoice payload structured for E-Invoicing compatibility if needed.
  static Map<String, dynamic> generateTaxCompliantInvoice(String countryName, Map<String, dynamic> invoice) {
    final config = getConfigForCountry(countryName);
    
    // Boilerplate for eventual integration
    Map<String, dynamic> compliantPayload = Map.from(invoice);
    compliantPayload['tax_meta'] = {
      'applied_tax_name': config.taxName,
      'is_einvoice_ready': config.hasEInvoicing,
      'provider': config.eInvoiceProvider ?? 'N/A'
    };

    return compliantPayload;
  }
}
