import 'dart:convert';
import 'dart:typed_data';

class QrService {
  /// Generates a QR data string based on company settings and invoice data.
  static String generateQrData({
    required String companyName,
    required String vatNumber,
    required DateTime timestamp,
    required double totalWithVat,
    required double vatAmount,
    required String country,
  }) {
    if (country == "السعودية") {
      return _generateZatcaTlv(companyName, vatNumber, timestamp, totalWithVat, vatAmount);
    } else {
      // Standard Generic format for other countries
      return "المنشأة: $companyName\nالرقم الضريبي: $vatNumber\nالتاريخ: ${timestamp.toIso8601String()}\nالإجمالي: $totalWithVat";
    }
  }

  /// Implements ZATCA (Saudi Arabia) Phase 1 TLV Encoding (Base64).
  static String _generateZatcaTlv(
    String sellerName,
    String vatRegistration,
    DateTime time,
    double total,
    double tax,
  ) {
    BytesBuilder builder = BytesBuilder();

    // Tag 1: Seller Name
    builder.addByte(1);
    List<int> sellerBytes = utf8.encode(sellerName);
    builder.addByte(sellerBytes.length);
    builder.add(sellerBytes);

    // Tag 2: VAT Registration Number
    builder.addByte(2);
    List<int> vatBytes = utf8.encode(vatRegistration);
    builder.addByte(vatBytes.length);
    builder.add(vatBytes);

    // Tag 3: Timestamp
    builder.addByte(3);
    String timestampStr = time.toIso8601String();
    List<int> timeBytes = utf8.encode(timestampStr);
    builder.addByte(timeBytes.length);
    builder.add(timeBytes);

    // Tag 4: Invoice Total (with VAT)
    builder.addByte(4);
    List<int> totalBytes = utf8.encode(total.toStringAsFixed(2));
    builder.addByte(totalBytes.length);
    builder.add(totalBytes);

    // Tag 5: VAT Total
    builder.addByte(5);
    List<int> taxBytes = utf8.encode(tax.toStringAsFixed(2));
    builder.addByte(taxBytes.length);
    builder.add(taxBytes);

    return base64.encode(builder.toBytes());
  }
}
