import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme_extension.dart';

class RecruitmentTab extends StatelessWidget {
  final List<Map<String, dynamic>> candidates;
  final VoidCallback onAddCandidate;
  final Function(Map<String, dynamic>) onHire;

  const RecruitmentTab({
    super.key,
    required this.candidates,
    required this.onAddCandidate,
    required this.onHire,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tr('hr.recruitment_tab'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textColor)),
            ElevatedButton.icon(
              onPressed: onAddCandidate,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black, size: 18),
              label: Text(tr('hr.new_employee'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: candidates.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: candidates.length,
                itemBuilder: (ctx, idx) => _buildCandidateCard(context, candidates[idx]),
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.handshake_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text("لا يوجد مرشحين حالياً", style: TextStyle(color: context.mutedText)),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, Map<String, dynamic> candidate) {
    final String name = candidate['name']?.toString() ?? '';
    final String job = candidate['job_title']?.toString() ?? 'N/A';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.obsidianGlass, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white10)
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryOrange.withValues(alpha: 0.1), 
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: primaryOrange))
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(job, style: TextStyle(color: context.mutedText, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.withValues(alpha: 0.2), 
            foregroundColor: Colors.greenAccent
          ),
          onPressed: () => onHire(candidate),
          child: const Text("توظيف", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
