import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/time_helper.dart';

class ManageDoctorsPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const ManageDoctorsPage({super.key, required this.shop});

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final shopId = widget.shop['id'].toString();
      final response = await Supabase.instance.client
          .from('doctors')
          .select('*, doctor_qualifications(qualification), doctor_availability(*)')
          .eq('shop_id', shopId)
          .order('name');
          
      if (mounted) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load doctors.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDoctor(String docId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: const Text('Are you sure you want to remove this doctor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('doctors').delete().eq('id', docId);
      await _fetchDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor removed successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting doctor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete doctor: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? doctorToEdit}) {
    final isEdit = doctorToEdit != null;
    final blue = const Color(0xFF2962FF);
    
    final nameController = TextEditingController(text: isEdit ? doctorToEdit['name'] : '');
    final qualController = TextEditingController();
    final limitController = TextEditingController(text: isEdit ? doctorToEdit['booking_limit']?.toString() : '');
    
    String? selectedDept = isEdit ? doctorToEdit['department'] : null;
    final Set<int> selectedDocDays = {};
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    // Initial data prep for Edit mode
    if (isEdit) {
      if (doctorToEdit['doctor_qualifications'] != null) {
        final qualsList = doctorToEdit['doctor_qualifications'] as List;
        qualController.text = qualsList.map((q) => q['qualification'].toString()).join(', ');
      }
      
      if (doctorToEdit['doctor_availability'] != null) {
        final availList = doctorToEdit['doctor_availability'] as List;
        if (availList.isNotEmpty) {
          for (var item in availList) {
             selectedDocDays.add(int.tryParse(item['day_of_week'].toString()) ?? 0);
          }
          // Use first available time as default for the picker
          final first = availList[0];
          final now = DateTime.now();
          final sTimeStr = first['start_time']?.toString();
          final eTimeStr = first['end_time']?.toString();
          
          if (sTimeStr != null) {
            final sDt = TimeHelper.parseTime(sTimeStr, now);
            if (sDt != null) startTime = TimeOfDay.fromDateTime(sDt);
          }
          if (eTimeStr != null) {
            final eDt = TimeHelper.parseTime(eTimeStr, now);
            if (eDt != null) endTime = TimeOfDay.fromDateTime(eDt);
          }
        }
      }
    }

    final departments = [
      'Cardiology', 'Neurology', 'Orthopedics', 'Pediatrics', 'Dermatology',
      'General Medicine', 'Gynecology', 'Oncology', 'ENT', 'Psychiatry',
      'Urology', 'Gastroenterology', 'Radiology', 'Anesthesiology', 'Emergency'
    ];

    Widget buildField({
      required TextEditingController ctrl,
      required String hint,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: blue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: keyboardType,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1A47CC), blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Icon(isEdit ? Icons.edit_note : Icons.person_add_outlined, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            isEdit ? 'Edit Doctor' : 'Add New Doctor',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Doctor Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 6),
                          buildField(ctrl: nameController, hint: 'e.g. Dr. Jane Doe', icon: Icons.person_outline),
                          
                          const SizedBox(height: 16),
                          const Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedDept,
                                hint: const Text('Select Department', style: TextStyle(fontSize: 14)),
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down, color: blue),
                                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 14)))).toList(),
                                onChanged: (v) => setDialogState(() => selectedDept = v),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text('Qualifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 6),
                          buildField(ctrl: qualController, hint: 'e.g. MBBS, MD', icon: Icons.school_outlined),

                          const SizedBox(height: 16),
                          const Text('Booking Limit (Daily)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 6),
                          buildField(ctrl: limitController, hint: 'e.g. 20', icon: Icons.format_list_numbered, keyboardType: TextInputType.number),

                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.blue),
                              SizedBox(width: 6),
                              Text('Availability Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: List.generate(7, (idx) {
                              final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                              final isSelected = selectedDocDays.contains(idx);
                              return FilterChip(
                                label: Text(days[idx], style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                selected: isSelected,
                                onSelected: (s) => setDialogState(() => s ? selectedDocDays.add(idx) : selectedDocDays.remove(idx)),
                                selectedColor: blue,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? blue : Colors.grey.shade300)),
                              );
                            }),
                          ),
                          
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: startTime);
                                    if (t != null) setDialogState(() => startTime = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.login, size: 16, color: blue),
                                        const SizedBox(width: 8),
                                        Text(startTime.format(context), style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: endTime);
                                    if (t != null) setDialogState(() => endTime = t);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout, size: 16, color: blue),
                                        const SizedBox(width: 8),
                                        Text(endTime.format(context), style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.trim().isEmpty || selectedDept == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Department required')));
                                  return;
                                }
                                Navigator.pop(ctx);
                                await _saveDoctor(
                                  isEdit: isEdit,
                                  docId: doctorToEdit?['id']?.toString(),
                                  name: nameController.text.trim(),
                                  dept: selectedDept!,
                                  quals: qualController.text.trim(),
                                  limit: limitController.text.trim(),
                                  days: selectedDocDays,
                                  sTime: startTime,
                                  eTime: endTime,
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: Text(isEdit ? 'Save Changes' : 'Add Doctor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveDoctor({
    required bool isEdit,
    String? docId,
    required String name,
    required String dept,
    required String quals,
    required String limit,
    required Set<int> days,
    required TimeOfDay sTime,
    required TimeOfDay eTime,
  }) async {
    setState(() => _isLoading = true);
    try {
      final shopId = widget.shop['id'].toString();
      final docData = {
        'shop_id': shopId,
        'name': name,
        'department': dept,
        'booking_limit': limit.isEmpty ? null : int.tryParse(limit),
      };

      String finalDocId;
      if (isEdit) {
        await Supabase.instance.client.from('doctors').update(docData).eq('id', docId!);
        finalDocId = docId;
      } else {
        final res = await Supabase.instance.client.from('doctors').insert(docData).select();
        finalDocId = res[0]['id'].toString();
      }

      // Handle Qualifications
      await Supabase.instance.client.from('doctor_qualifications').delete().eq('doctor_id', finalDocId);
      if (quals.isNotEmpty) {
        final qList = quals.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (qList.isNotEmpty) {
          await Supabase.instance.client.from('doctor_qualifications').insert(qList.map((q) => {'doctor_id': finalDocId, 'qualification': q}).toList());
        }
      }

      // Handle Availability
      await Supabase.instance.client.from('doctor_availability').delete().eq('doctor_id', finalDocId);
      if (days.isNotEmpty) {
        final startStr = "${sTime.hour.toString().padLeft(2, '0')}:${sTime.minute.toString().padLeft(2, '0')}:00";
        final endStr = "${eTime.hour.toString().padLeft(2, '0')}:${eTime.minute.toString().padLeft(2, '0')}:00";
        final availInserts = days.map((d) => {
          'doctor_id': finalDocId,
          'day_of_week': d,
          'start_time': startStr,
          'end_time': endStr,
        }).toList();
        await Supabase.instance.client.from('doctor_availability').insert(availInserts);
      }

      await _fetchDoctors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Updated successfully!' : 'Added successfully!')));
      }
    } catch (e) {
      debugPrint('Error saving doctor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
          : _doctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No doctors added yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Doctor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doc = _doctors[index];
                    final String name = doc['name'] ?? 'Unknown';
                    final String dept = doc['department'] ?? '';
                    final String? image = doc['image_url'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: image != null && image.isNotEmpty
                                  ? NetworkImage(image)
                                  : null,
                              child: image == null || image.isEmpty
                                  ? Icon(Icons.person, color: Colors.blue[300], size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dept,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(doctorToEdit: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteDoctor(doc['id'].toString()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _doctors.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              backgroundColor: const Color(0xFF2962FF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
