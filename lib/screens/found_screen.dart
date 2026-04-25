import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class FoundScreen extends StatefulWidget {
  const FoundScreen({super.key});

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _lostItems = [];
  bool _isLoading = true;
  bool _showCreateForm = false;

  final _formKey = GlobalKey<FormState>();
  final _objectNameController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _selectedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadLostItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _objectNameController.dispose();
    _busNumberController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLostItems() async {
    try {
      final items = await FirebaseService.getAllLostItems();
      setState(() {
        _lostItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('bg', 'BG'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      if (_selectedImage != null) {
        String fileName = 'found_${DateTime.now().millisecondsSinceEpoch}.jpg';
        photoUrl = await FirebaseService.uploadImage(
          _selectedImage!.path,
          fileName,
        );
      }

      final authProvider = context.read<AuthProvider>();
      final itemData = {
        'userId': authProvider.firebaseUser?.uid ?? '',
        'objectName': _objectNameController.text.trim(),
        'busNumber': _busNumberController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'time': _selectedTime.format(context),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'photoUrl': photoUrl,
        'contactName': _contactNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseService.addFoundItem(itemData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сигналът за намерен предмет е подаден!'),
            backgroundColor: AppColors.accent,
          ),
        );
        setState(() => _showCreateForm = false);
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _objectNameController.clear();
    _busNumberController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _contactNameController.clear();
    _phoneController.clear();
    _selectedImage = null;
  }

  List<Map<String, dynamic>> _filteredItems = [];
  
  void _filterItems(String query) {
    if (query.isEmpty) {
      _filteredItems = _lostItems;
    } else {
      _filteredItems = _lostItems.where((item) {
        final objectName = item['objectName']?.toString().toLowerCase() ?? '';
        final description = item['description']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return objectName.contains(searchLower) || description.contains(searchLower);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showCreateForm ? 'Подай сигнал за намерен предмет' : AppStrings.found),
      ),
      body: _showCreateForm ? _buildCreateForm() : _buildListView(),
      floatingActionButton: _showCreateForm
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createReport),
            ),
    );
  }

  Widget _buildListView() {
    _filteredItems = _lostItems;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.search,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterItems,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? const Center(child: Text(AppStrings.noItemsFound))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return _buildItemCard(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['objectName'] ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(item['description'] ?? ''),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(item['date']?.toString().split('T')[0] ?? ''),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(item['location'] ?? '')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 4),
                Text(item['phone'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _objectNameController,
            decoration: const InputDecoration(
              labelText: AppStrings.foundObject,
              prefixIcon: Icon(Icons.inventory_2),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете име на предмета';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _busNumberController,
            decoration: const InputDecoration(
              labelText: AppStrings.busNumber,
              prefixIcon: Icon(Icons.confirmation_number),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете номер на автобус';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: AppStrings.date,
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: AppStrings.time,
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_selectedTime.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: AppStrings.location,
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете местоположение';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: AppStrings.description,
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете описание';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_camera),
            label: Text(
              _selectedImage != null ? 'Снимка избрана' : AppStrings.uploadPhoto,
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactNameController,
            decoration: const InputDecoration(
              labelText: AppStrings.contactName,
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете име за контакт';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: AppStrings.phone,
              prefixIcon: Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Моля, въведете телефон';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _showCreateForm = false);
                    _clearForm();
                  },
                  child: const Text('Отказ'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.submit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}