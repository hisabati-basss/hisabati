import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/currency_service.dart';
import '../../theme/app_theme_extension.dart';

class EmployeeListView extends StatelessWidget {
  final List<Map<String, dynamic>> employees;
  final bool isMobile;
  final Function(Map<String, dynamic>) onEmployeeTap;
  final Color Function(DateTime?) statusColorPicker;
  final String currency;

  const EmployeeListView({
    super.key,
    required this.employees,
    required this.isMobile,
    required this.onEmployeeTap,
    required this.statusColorPicker,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return Center(
        child: Text(
          tr('hr.no_employees'),
          style: TextStyle(color: context.mutedText),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('hr.employee_list_title'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textColor)),
              Icon(Icons.filter_list_rounded, color: context.mutedText, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isMobile ? 2.2 : 2.8,
            ),
            itemCount: employees.length,
            itemBuilder: (context, index) => _EmployeeGlassCard(
              employee: employees[index],
              onTap: () => onEmployeeTap(employees[index]),
              statusColorPicker: statusColorPicker,
              currency: currency,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EmployeeGlassCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final VoidCallback onTap;
  final Color Function(DateTime?) statusColorPicker;
  final String currency;

  const _EmployeeGlassCard({
    required this.employee,
    required this.onTap,
    required this.statusColorPicker,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final empName = employee['name']?.toString() ?? '';
    final empJobTitle = employee['job_title']?.toString() ?? 'N/A';
    final empStatus = employee['status']?.toString() ?? 'active';
    
    DateTime? idExpiryDate;
    try {
      idExpiryDate = employee['id_expiry_date'] != null 
        ? DateTime.parse(employee['id_expiry_date'].toString()) 
        : null;
    } catch (_) {}

    final double basic = (employee['basic_salary'] as num?)?.toDouble() ?? 0;
    final double housing = (employee['housing_allowance'] as num?)?.toDouble() ?? 0;
    final double transport = (employee['transport_allowance'] as num?)?.toDouble() ?? 0;
    final double netSalary = basic + housing + transport; // Simplified for card view

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: context.glassBlurLevel, sigmaY: context.glassBlurLevel),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.sheetGlass,
              borderRadius: BorderRadius.circular(context.cardRadius),
              border: Border.all(color: context.glassBorder.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryOrange.withValues(alpha: 0.1),
                      child: Text(
                        empName.isNotEmpty ? empName[0] : '?', 
                        style: const TextStyle(color: primaryOrange, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(empName, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(empJobTitle, style: TextStyle(color: context.mutedText, fontSize: 10)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            empStatus.toUpperCase(), 
                            style: const TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)
                          ),
                        ),
                        if (idExpiryDate != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              color: statusColorPicker(idExpiryDate),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('hr.estimated_salary'), style: TextStyle(color: context.mutedText, fontSize: 9)),
                        Text("${netSalary.toStringAsFixed(0)} ${CurrencyService.getSymbol(currency)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryOrange)),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: context.mutedText.withValues(alpha: 0.3)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
