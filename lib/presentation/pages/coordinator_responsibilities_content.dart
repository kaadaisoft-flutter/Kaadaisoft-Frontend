import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';

class CoordinatorResponsibilitiesContent extends StatefulWidget {
  final String numericId;
  final String familyId;
  final VoidCallback onBack;

  const CoordinatorResponsibilitiesContent({
    super.key, 
    required this.numericId, 
    required this.familyId,
    required this.onBack,
  });

  @override
  State<CoordinatorResponsibilitiesContent> createState() => _CoordinatorResponsibilitiesContentState();
}

class _CoordinatorResponsibilitiesContentState extends State<CoordinatorResponsibilitiesContent> {
  Map<String, dynamic>? _userData;
  List<dynamic> _assignedMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Assigned Village Members
      final assignedRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-assigned-members/${widget.familyId}'));
      // Fetch Villages for "Assigned Villages" display
      final villagesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-villages/${widget.familyId}'));

      if (assignedRes.statusCode == 200 && villagesRes.statusCode == 200) {
        final assignedData = jsonDecode(assignedRes.body)['data'];
        final villagesData = jsonDecode(villagesRes.body)['data'] as List;
        
        String villageNames = villagesData.map((v) => v['village_name']).join(', ');

        setState(() {
          _userData = {'AssignedVillages': villageNames.isEmpty ? 'None' : villageNames};
          _assignedMembers = assignedData.where((m) => m['MemberRole'] == 'Head').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingSpinner(message: 'Loading responsibilities...');
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_userData == null) return const Center(child: Text('No data found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_ind, color: Color(0xFF5D1712), size: 28),
                  SizedBox(width: 12),
                  Text('Responsibilities', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: widget.onBack),
            ],
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              bool isMobile = MediaQuery.of(context).size.width < 800;
              final labelWidget = SizedBox(
                width: isMobile ? double.infinity : 200,
                child: Text('Assigned Villages:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              );
              final valueWidget = Text(
                _userData!['AssignedVillages'] ?? 'None',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelWidget, const SizedBox(height: 8), valueWidget],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelWidget, Expanded(child: valueWidget)],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.location_city, color: Color(0xFF5D1712), size: 24),
              const SizedBox(width: 12),
              Text('Assigned Members (${_assignedMembers.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignedMembersTable(),
        ],
      ),
    );
  }

  Widget _buildAssignedMembersTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
            headingRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF5D1712)),
          columns: const [
            DataColumn(label: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('MOBILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: _assignedMembers.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['Name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 11, color: const Color(0xFF5D1712))),
                ],
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m['Gender'] == 'Male' ? Icons.male : Icons.female, size: 16, color: const Color(0xFF5D1712)),
                  const SizedBox(width: 4),
                  Text(m['Gender'] ?? 'N/A'),
                ],
              )),
              DataCell(Text(m['Phonenumber']?.toString() ?? 'N/A')),
              DataCell(Text(m['Village'] ?? '-')),
            ]);
          }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
