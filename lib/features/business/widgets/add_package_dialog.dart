import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/backend/controllers/PackageController.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';

/// A modal dialog widget that facilitates the creation and submission of new food packages by business providers.
class AddPackageDialog extends StatefulWidget {
  final String nextId;
  final Function(Map<String, dynamic>) onPackageAdded;

  const AddPackageDialog(
      {super.key, required this.nextId, required this.onPackageAdded});

  @override
  State<AddPackageDialog> createState() => _AddPackageDialogState();
}

class _AddPackageDialogState extends State<AddPackageDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _startTime = '08:00';
  String _endTime = '17:00';
  DateTime _selectedDate = DateTime.now();
  bool _termsApproved = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up text editing controllers to prevent memory leaks upon widget destruction
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Generates 30-minute incremental time slots spanning a 24-hour cycle.
  List<String> get _dailyTimeSlots {
    return List.generate(48, (index) {
      final hour = (index ~/ 2).toString().padLeft(2, '0');
      final minute = (index % 2 == 0) ? '00' : '30';
      return '$hour:$minute';
    });
  }

  /// Opens the date picker dialog to select package pickup dates.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Parses a time string and combines it with a target date instance.
  DateTime _parseTime(DateTime baseDate, String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  /// Validates form input fields and terms approval state.
  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty && _termsApproved;
  }

  /// Handles package creation and submission to the backend database controller.
  Future<void> _submitData() async {
    if (!_isFormValid) return;

    setState(() => _isUploading = true);

    try {
      final profileCtrl = context.read<ProfileController>();
      final packageCtrl = context.read<PackageController>();

      final businessId = profileCtrl.currentBusinessData?.businessId;
      if (businessId == null || businessId.isEmpty) {
        throw Exception('Error: Business ID not found.');
      }

      final int enteredPrice = int.tryParse(_priceController.text.trim()) ?? 0;
      final DateTime pickupStart = _parseTime(_selectedDate, _startTime);
      final DateTime pickupEnd = _parseTime(_selectedDate, _endTime);

      final success = await packageCtrl.createPackage(
        businessId: businessId,
        title: _nameController.text.trim(),
        originalPrice: enteredPrice.toDouble(),
        salePrice: enteredPrice.toDouble(),
        quantity: 1,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
      );

      if (success && mounted) {
        widget.onPackageAdded({
          'id': widget.nextId,
          'name': _nameController.text.trim(),
          'price': enteredPrice,
          'startTime': _startTime,
          'endTime': _endTime,
          'date': _selectedDate,
          'status': 'available',
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('החבילה הועלתה בהצלחה!', textAlign: TextAlign.right),
            backgroundColor: Colors.green));
      } else {
        throw Exception(packageCtrl.errorMessage ?? 'Failed to create package');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), textAlign: TextAlign.right),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeOptions = _dailyTimeSlots;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('העלאת חבילה חדשה',
            style: TextStyle(
                color: AppColors.deepBlue, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                enabled: !_isUploading,
                onChanged: (val) => setState(() {}),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(
                    labelText: 'שם החבילה', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                enabled: !_isUploading,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(
                    labelText: 'מחיר בש"ח (השאר ריק או 0 עבור חינם)',
                    border: OutlineInputBorder(),
                    prefixText: '₪ '),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isUploading ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'תאריך איסוף', border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black)),
                      Icon(Icons.calendar_today,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _startTime,
                      dropdownColor:
                          isDark ? AppColors.darkSurface : Colors.white,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'משעה', border: OutlineInputBorder()),
                      items: timeOptions
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: _isUploading
                          ? null
                          : (val) =>
                              setState(() => _startTime = val ?? _startTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _endTime,
                      dropdownColor:
                          isDark ? AppColors.darkSurface : Colors.white,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'עד שעה', border: OutlineInputBorder()),
                      items: timeOptions
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: _isUploading
                          ? null
                          : (val) => setState(() => _endTime = val ?? _endTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: Text('קראתי ואני מאשר את תנאי השימוש',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black)),
                value: _termsApproved,
                activeColor: AppColors.deepBlue,
                checkColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: _isUploading
                    ? null
                    : (bool? value) =>
                        setState(() => _termsApproved = value ?? false),
              ),
            ],
          ),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('ביטול', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: (_isFormValid && !_isUploading) ? _submitData : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepBlue,
              disabledBackgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.grey.shade500,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('אישור והעלאה'),
          ),
        ],
      ),
    );
  }
}
