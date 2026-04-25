import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _problems = [];
  List<Map<String, dynamic>> _lostItems = [];
  List<Map<String, dynamic>> _foundItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    try {
      final problems = await FirebaseService.getUserProblems(user.uid);
      final lost = await FirebaseService.getUserLostItems(user.uid);
      final found = await FirebaseService.getUserFoundItems(user.uid);

      setState(() {
        _problems = problems;
        _lostItems = lost;
        _foundItems = found;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myReports),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Проблеми'),
            Tab(text: 'Изгубени'),
            Tab(text: 'Намерени'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProblemList(),
                _buildItemList(_lostItems),
                _buildItemList(_foundItems),
              ],
            ),
    );
  }

  Widget _buildProblemList() {
    if (_problems.isEmpty) {
      return const Center(child: Text(AppStrings.noItemsFound));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _problems.length,
      itemBuilder: (context, index) {
        final problem = _problems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        problem['title'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _buildStatusChip(problem['status'] ?? ''),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Линия: ${problem['busLine'] ?? ''}'),
                const SizedBox(height: 4),
                Text(problem['description'] ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(problem['date']?.toString().split('T')[0] ?? ''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text(AppStrings.noItemsFound));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                Text('Автобус: ${item['busNumber'] ?? ''}'),
                const SizedBox(height: 4),
                Text(item['description'] ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14),
                    const SizedBox(width: 4),
                    Text(item['date']?.toString().split('T')[0] ?? ''),
                    const SizedBox(width: 16),
                    const Icon(Icons.phone, size: 14),
                    const SizedBox(width: 4),
                    Text(item['phone'] ?? ''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'submitted':
        color = Colors.blue;
        text = 'Подаден';
        break;
      case 'in_progress':
        color = Colors.orange;
        text = 'В процес';
        break;
      case 'resolved':
        color = AppColors.accent;
        text = 'Решен';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}