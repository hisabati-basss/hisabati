/// Tafqeet (Arabic Number to Text) Utility for Hisabati App
/// Handles conversion of currency amounts to proper Arabic grammatical form.
class Tafqeet {
  static const List<String> _ones = [
    "", "واحد", "اثنان", "ثلاثة", "أربعة", "خمسة", "ستة", "سبعة", "ثمانية", "تسعة", "عشرة",
    "أحد عشر", "اثنا عشر", "ثلاثة عشر", "أربعة عشر", "خمسة عشر", "ستة عشر", "سبعة عشر", "ثمانية عشر", "تسعة عشر"
  ];

  static const List<String> _tens = [
    "", "عشرة", "عشرون", "ثلاثون", "أربعون", "خمسون", "ستون", "سبعون", "ثمانون", "تسعون"
  ];

  static const List<String> _hundreds = [
    "", "مائة", "مائتان", "ثلاثمائة", "أربعمائة", "خمسمائة", "ستمائة", "سبعمائة", "ثمانمائة", "تسعمائة"
  ];

  static String convert(double amount, {String currency = "ريال", String subunit = "هللة"}) {
    if (amount == 0) return "صفر $currency";

    int whole = amount.floor();
    int decimal = ((amount - whole) * 100).round();

    String result = _convertGroup(whole);
    String finalString = result + " " + currency;

    if (decimal > 0) {
      finalString += " و " + _convertGroup(decimal) + " " + subunit;
    }

    return "$finalString فقط لا غير";
  }

  static String _convertGroup(int num) {
    if (num == 0) return "";

    if (num < 20) return _ones[num];
    if (num < 100) {
      int ten = num ~/ 10;
      int unit = num % 10;
      return (unit > 0 ? _ones[unit] + " و " : "") + _tens[ten];
    }
    if (num < 1000) {
      int hundred = num ~/ 100;
      int rest = num % 100;
      return _hundreds[hundred] + (rest > 0 ? " و " + _convertGroup(rest) : "");
    }
    if (num < 2000) {
      return "ألف" + (num % 1000 > 0 ? " و " + _convertGroup(num % 1000) : "");
    }
    if (num < 3000) {
      return "ألفان" + (num % 1000 > 0 ? " و " + _convertGroup(num % 1000) : "");
    }
    if (num < 10000) {
      int thousands = num ~/ 1000;
      int rest = num % 1000;
      return _ones[thousands] + " آلاف" + (rest > 0 ? " و " + _convertGroup(rest) : "");
    }
    
    // For larger numbers (simplified for now but covers common ranges)
    int thousands = num ~/ 1000;
    int rest = num % 1000;
    return _convertGroup(thousands) + " ألف" + (rest > 0 ? " و " + _convertGroup(rest) : "");
  }
}
