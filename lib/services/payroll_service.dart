import '../services/database_helper.dart';

/// Configuration for country-specific payroll rules (QuickBooks-style)
class CountryPayrollConfig {
  final String countryName;
  final double socialInsuranceRate; // e.g., GOSI 0.0975 (9.75%)
  final bool hasIncomeTax;
  final List<TaxSlab>? taxSlabs;
  final double housingAllowanceMultiplier;
  final double eosDaysFirst5; // days per year for first 5 years
  final double eosDaysAfter5; // days per year after 5 years

  CountryPayrollConfig({
    required this.countryName,
    this.socialInsuranceRate = 0,
    this.hasIncomeTax = false,
    this.taxSlabs,
    this.housingAllowanceMultiplier = 0.25,
    this.eosDaysFirst5 = 15,
    this.eosDaysAfter5 = 30,
  });
}

class TaxSlab {
  final double min;
  final double max;
  final double rate;
  TaxSlab(this.min, this.max, this.rate);
}

class PayrollService {
  final DatabaseHelper _db = DatabaseHelper();

  // Predefined Global Rules
  static final Map<String, CountryPayrollConfig> globalConfigs = {
    "hr.nationalities.saudi": CountryPayrollConfig(
      countryName: "المملكة العربية السعودية",
      socialInsuranceRate: 0.0975, // GOSI 9.75% for Employee (Basic + Housing)
      housingAllowanceMultiplier: 0.25,
      eosDaysFirst5: 15,
      eosDaysAfter5: 30,
    ),
    "hr.nationalities.egypt": CountryPayrollConfig(
      countryName: "جمهورية مصر العربية",
      socialInsuranceRate: 0.11,
      hasIncomeTax: true,
      taxSlabs: [
        TaxSlab(0, 15000, 0),
        TaxSlab(15000, 30000, 0.025),
        TaxSlab(30000, 45000, 0.10),
        TaxSlab(45000, 60000, 0.15),
        TaxSlab(60000, 200000, 0.20),
        TaxSlab(200000, 400000, 0.225),
        TaxSlab(400000, 9999999, 0.25),
      ],
      eosDaysFirst5: 30,
      eosDaysAfter5: 30,
    ),
    "hr.nationalities.jordan": CountryPayrollConfig(
      countryName: "المملكة الأردنية الهاشمية",
      socialInsuranceRate: 0.065,
      hasIncomeTax: true,
      taxSlabs: [
        TaxSlab(0, 5000, 0), 
        TaxSlab(5000, 10000, 0.05), 
        TaxSlab(10000, 999999, 0.10)
      ],
      eosDaysFirst5: 30,
      eosDaysAfter5: 30,
    ),
    "hr.nationalities.uae": CountryPayrollConfig(
      countryName: "الإمارات العربية المتحدة",
      socialInsuranceRate: 0.05,
      eosDaysFirst5: 21,
      eosDaysAfter5: 30,
    ),
  };

  // ==========================================
  // HR PRO: GLOBAL PAYROLL ENGINE
  // ==========================================

  /// Calculates net salary with global logic (Taxes, Insurance, Allowances)
  Map<String, double> calculateNetSalary(
    Map<String, dynamic> employee, {
    int absenceDays = 0,
    double overtimeHours = 0.0,
    List<Map<String, dynamic>> customItems = const [],
    List<Map<String, dynamic>> activeLoans = const [],
  }) {
    final String rawNationality = employee['nationality']?.toString() ?? "hr.nationalities.saudi";
    String normalizedNationality = rawNationality;
    if (rawNationality == "السعودية") normalizedNationality = "hr.nationalities.saudi";
    else if (rawNationality == "مصر") normalizedNationality = "hr.nationalities.egypt";
    else if (rawNationality == "الإمارات") normalizedNationality = "hr.nationalities.uae";
    else if (rawNationality == "الأردن") normalizedNationality = "hr.nationalities.jordan";

    final config = globalConfigs[normalizedNationality] ?? CountryPayrollConfig(countryName: "Universal");

    final double basic = (employee['basic_salary'] as num?)?.toDouble() ?? (employee['salary'] as num?)?.toDouble() ?? 0;
    final double housing = (employee['housing_allowance'] as num?)?.toDouble() ?? (employee['housing'] as num?)?.toDouble() ?? (basic * config.housingAllowanceMultiplier);
    final double transport = (employee['transport_allowance'] as num?)?.toDouble() ?? (employee['transport'] as num?)?.toDouble() ?? 0;
    
    final double dayRate = basic / 30.0;
    final double hourlyRate = dayRate / 8.0;
    final double absenceDeduction = dayRate * absenceDays;
    final double overtimePay = hourlyRate * 1.5 * overtimeHours;
    
    double customEarnings = 0.0;
    double customDeductions = 0.0;
    for (var item in customItems) {
      if (item['type'] == 'earning') customEarnings += (item['amount'] as num?)?.toDouble() ?? 0;
      if (item['type'] == 'deduction') customDeductions += (item['amount'] as num?)?.toDouble() ?? 0;
    }

    double loanDeductions = 0.0;
    for (var loan in activeLoans) {
      double balance = (loan['balance'] as num?)?.toDouble() ?? 0;
      double installment = (loan['installment'] as num?)?.toDouble() ?? 0;
      if (balance > 0) {
        loanDeductions += installment > balance ? balance : installment;
      }
    }

    // 1. Social Insurance Calculation
    final double insuranceBasis = basic + housing; // Often insurance is based on subsets of salary
    final double socialInsurance = insuranceBasis * config.socialInsuranceRate;

    // 2. Gross Salary before Tax
    final double grossBeforeTax = basic + housing + transport + overtimePay + customEarnings;

    // 3. Tax Calculation (QuickBooks slab logic)
    double incomeTax = 0.0;
    if (config.hasIncomeTax && config.taxSlabs != null) {
      double taxableAmount = grossBeforeTax - socialInsurance - 1000; // Simplified monthly personal exemption
      if (taxableAmount > 0) {
        for (var slab in config.taxSlabs!) {
          if (taxableAmount > slab.min) {
            double slabBasement = taxableAmount > slab.max ? slab.max - slab.min : taxableAmount - slab.min;
            incomeTax += slabBasement * slab.rate;
            if (taxableAmount <= slab.max) break;
          }
        }
      }
    }

    final double totalDeduction = socialInsurance + incomeTax + absenceDeduction + loanDeductions + customDeductions;
    final double netSalary = grossBeforeTax - totalDeduction;

    return {
      'basic': basic,
      'housing': housing,
      'transport': transport,
      'overtime': overtimePay,
      'customEarnings': customEarnings,
      'insurance': socialInsurance,
      'tax': incomeTax,
      'absence_deduction': absenceDeduction,
      'loan_deductions': loanDeductions,
      'customDeductions': customDeductions,
      'gross': grossBeforeTax,
      'net': netSalary,
    };
  }

  /// Processes monthly payroll for all active employees
  Future<Map<String, dynamic>> processMonthlyPayroll(String month) async {
    final db = await _db.database;
    int employeesProcessed = 0;
    double totalPayrollAmount = 0.0;

    final employees = await _db.getEmployees();

    for (var emp in employees) {
      final empId = emp['id']?.toString() ?? '';
      if (emp['status'] != 'active') continue;
      
      final existing = await db.query('salary_slips', where: 'employee_id = ? AND month = ?', whereArgs: [empId, month]);
      if (existing.isNotEmpty) continue;

      int absenceDays = await getAbsenceCount(empId, month);
      final activeLoans = await _db.getEmployeeLoans(employeeId: empId);

      final breakdown = calculateNetSalary(
        emp,
        absenceDays: absenceDays,
        activeLoans: activeLoans.where((l) => l['status'] == 'ACTIVE').toList(),
      );

      final double netAmount = breakdown['net']!;
      if (netAmount < 0) continue;

      await _db.generateSalarySlip({
        'employee_id': empId,
        'month': month,
        'basic_salary': breakdown['basic'],
        'housing_allowance': breakdown['housing'],
        'transport_allowance': breakdown['transport'],
        'overtime': breakdown['overtime'],
        'custom_earnings': breakdown['customEarnings'],
        'insurance_deduction': breakdown['insurance'],
        'tax_deduction': breakdown['tax'],
        'absence_deduction': breakdown['absence_deduction'],
        'loan_deduction': breakdown['loan_deductions'],
        'custom_deductions': (breakdown['customDeductions'] ?? 0) + (breakdown['tax'] ?? 0),
        'net_salary': netAmount,
        'payment_status': 'draft',
        'cost_center_id': emp['cost_center_id'],
      });

      // Journal: Salary Payable with Cost Center (Phase 7.3)
      final String? costCenter = emp['cost_center_id']?.toString();
      await _db.saveManualJournalEntry(
        date: DateTime.now().toIso8601String().split('T')[0],
        description: 'استحقاق رواتب شهر $month - ${emp['name']}',
        lines: [
          {'account_id': 'ACC_SALARY_EXPENSE', 'debit': breakdown['gross'], 'credit': 0.0, 'cost_center_id': costCenter},
          {'account_id': 'ACC_PAYABLE_SALARY', 'debit': 0.0, 'credit': netAmount, 'cost_center_id': costCenter},
          {'account_id': 'ACC_PAYABLE_TAXES', 'debit': 0.0, 'credit': breakdown['tax'], 'cost_center_id': costCenter},
          {'account_id': 'ACC_PAYABLE_GOSI', 'debit': 0.0, 'credit': breakdown['insurance'], 'cost_center_id': costCenter},
        ],
      );

      employeesProcessed++;
      totalPayrollAmount += netAmount;
    }

    return {
      'success': true,
      'employees_processed': employeesProcessed,
      'total_amount': totalPayrollAmount,
      'slips_created': employeesProcessed,
      'month': month,
    };
  }

  // ==========================================
  // HR PRO: EOS (Global Standard)
  // ==========================================

  Map<String, dynamic> calculateEndOfService(Map<String, dynamic> employee) {
    final hireDateStr = employee['hiring_date']?.toString() ?? employee['hire_date']?.toString();
    if (hireDateStr == null || hireDateStr.isEmpty) return {'error': 'No hiring date found'};

    final hireDate = DateTime.tryParse(hireDateStr);
    if (hireDate == null) return {'error': 'Invalid hiring date'};

    final int daysEmployed = DateTime.now().difference(hireDate).inDays;
    final double yearsEmployed = daysEmployed / 365.25;

    final double basic = (employee['basic_salary'] as num?)?.toDouble() ?? (employee['salary'] as num?)?.toDouble() ?? 0;
    final double housing = (employee['housing_allowance'] as num?)?.toDouble() ?? (employee['housing'] as num?)?.toDouble() ?? 0;
    final double transport = (employee['transport_allowance'] as num?)?.toDouble() ?? (employee['transport'] as num?)?.toDouble() ?? 0;
    final double grossMonthly = basic + housing + transport;

    final String rawNationality = employee['nationality']?.toString() ?? "hr.nationalities.saudi";
    String normalizedNationality = rawNationality;
    if (rawNationality == "السعودية") normalizedNationality = "hr.nationalities.saudi";
    else if (rawNationality == "مصر") normalizedNationality = "hr.nationalities.egypt";
    else if (rawNationality == "الإمارات") normalizedNationality = "hr.nationalities.uae";
    else if (rawNationality == "الأردن") normalizedNationality = "hr.nationalities.jordan";

    final config = globalConfigs[normalizedNationality] ?? CountryPayrollConfig(countryName: "Universal");

    double gratuityAmount;
    if (yearsEmployed <= 5) {
      gratuityAmount = (grossMonthly * (config.eosDaysFirst5 / 30)) * yearsEmployed;
    } else {
      gratuityAmount = ((grossMonthly * (config.eosDaysFirst5 / 30)) * 5) + 
                       (grossMonthly * (config.eosDaysAfter5 / 30) * (yearsEmployed - 5));
    }

    final double dayRate = basic / 30;
    final double annualLeave = (employee['annual_leave_balance'] as num?)?.toDouble() ?? 0;
    final double vacationPay = annualLeave > 0 ? (annualLeave * dayRate) : 0;
    final double totalPayout = gratuityAmount + vacationPay;

    return {
      'yearsEmployed': yearsEmployed,
      'gratuityAmount': gratuityAmount,
      'vacationPay': vacationPay,
      'totalPayout': totalPayout,
    };
  }

  // ==========================================
  // GENERAL HR LOGIC
  // ==========================================

  Future<void> submitLeaveRequest(Map<String, dynamic> request) async {
    await _db.addLeaveRequest(request);
  }

  Future<void> updateLeaveStatus(String requestId, String newStatus) async {
    await _db.updateLeaveRequestStatus(requestId, newStatus);
  }

  Future<int> getAbsenceCount(String employeeId, String month) async {
    final logs = await _db.getAttendanceLogs(employeeId: employeeId);
    return logs.where((l) {
      final date = l['date']?.toString() ?? '';
      return date.startsWith(month) && l['status'] == 'absent';
    }).length;
  }

  Future<void> addEmployee(Map<String, dynamic> emp) async {
    await _db.addEmployee(emp);
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _db.updateEmployee({'id': id, ...data});
  }

  Future<void> deleteEmployee(String id) async {
    await _db.deleteEmployee(id);
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    return await _db.getEmployees();
  }

  Future<void> submitLoanRequest(Map<String, dynamic> loan) async {
    await _db.addEmployeeLoan({
      'employee_id': loan['employee_id'],
      'amount': loan['total_amount'],
      'monthly_installment': loan['installment_amount'],
      'balance': loan['total_amount'],
      'start_date': loan['request_date'] ?? DateTime.now().toIso8601String(),
      'status': 'ACTIVE',
    });
  }
}
