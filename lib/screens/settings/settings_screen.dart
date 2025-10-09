import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/backup_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_strings.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = false;
  List<FileSystemEntity> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    final files = await _backupService.getBackupFiles();
    setState(() {
      _backupFiles = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Backup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBackupFiles,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLanguageSection(),
                    const SizedBox(height: 24),
                    _buildBackupSection(),
                    const SizedBox(height: 24),
                    _buildDataManagementSection(),
                    const SizedBox(height: 24),
                    _buildBackupHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLanguageSection() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isBengali = languageProvider.isBengali;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.language(isBengali),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.selectLanguage(isBengali),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<bool>(
                      title: Text(AppStrings.english(isBengali)),
                      value: false,
                      groupValue: isBengali,
                      onChanged: (value) {
                        if (value == false) {
                          languageProvider.setEnglish();
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      title: Text(AppStrings.bengali(isBengali)),
                      value: true,
                      groupValue: isBengali,
                      onChanged: (value) {
                        if (value == true) {
                          languageProvider.setBengali();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup & Restore',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.backup, color: Colors.white),
                  ),
                  title: const Text('Create Backup'),
                  subtitle: const Text('Create a backup of all your data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _createBackup,
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.share, color: Colors.white),
                  ),
                  title: const Text('Share Backup'),
                  subtitle: const Text('Create and share backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _shareBackup,
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.restore, color: Colors.white),
                  ),
                  title: const Text('Restore from File'),
                  subtitle: const Text('Restore data from backup file'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _restoreFromFile,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Management',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all products, shops, and deliveries'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showClearDataDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.analytics, color: Colors.white),
                  ),
                  title: const Text('Database Statistics'),
                  subtitle: const Text('View database size and statistics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showDatabaseStats,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Backup History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              onPressed: _loadBackupFiles,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _backupFiles.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.backup,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No backups found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Column(
                children: _backupFiles.map((file) => _buildBackupFileCard(file)).toList(),
              ),
      ],
    );
  }

  Widget _buildBackupFileCard(FileSystemEntity file) {
    final fileName = file.path.split('/').last;
    final dateStr = fileName.replaceAll('stock_tracker_backup_', '').replaceAll('.json', '');

    DateTime? date;
    try {
      date = DateTime.parse(dateStr.replaceAll('-', ':'));
    } catch (e) {
      date = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.folder, color: Colors.white),
        ),
        title: Text(date != null
            ? DateFormat('MMM dd, yyyy - HH:mm').format(date)
            : fileName),
        subtitle: FutureBuilder<Map<String, dynamic>>(
          future: _backupService.getBackupInfo(file.path),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final info = snapshot.data!;
              return Text(
                '${info['products_count']} products, ${info['shops_count']} shops, ${info['deliveries_count']} deliveries',
              );
            }
            return const Text('Loading info...');
          },
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'restore':
                await _restoreBackup(file.path);
                break;
              case 'delete':
                await _deleteBackup(file.path);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _backupService.createBackup();
      setState(() => _isLoading = false);
      await _loadBackupFiles();

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Backup created successfully'),
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () => _loadBackupFiles(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error creating backup: $e')),
        );
      }
    }
  }

  Future<void> _shareBackup() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _backupService.shareBackup();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error sharing backup: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromFile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        await _restoreBackup(result.files.single.path!);
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all current data with the backup data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _backupService.restoreBackup(filePath);
        setState(() => _isLoading = false);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Backup restored successfully')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error restoring backup: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _backupService.deleteBackupFile(filePath);
        await _loadBackupFiles();

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Backup deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error deleting backup: $e')),
          );
        }
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete ALL data including products, shops, deliveries, and transactions. This action cannot be undone!\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _backupService.clearAllData();

        // Refresh all providers to clear cached data
        if (mounted) {
          context.read<ProductProvider>().clearData();
          context.read<ShopProvider>().clearData();
          context.read<DeliveryProvider>().clearData();
        }

        setState(() => _isLoading = false);
        await _loadBackupFiles(); // Refresh backup files list

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('All data cleared successfully')),
          );

          // Pop back to home screen and ensure dashboard refreshes
          navigator.popUntil((route) => route.isFirst);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDatabaseStats() async {
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final backupService = BackupService();
      final backupData = await backupService.gatherAllData();
      final data = backupData['data'] as Map<String, dynamic>;

      final products = data['products'] as List;
      final shops = data['shops'] as List;
      final deliveries = data['deliveries'] as List;
      final transactions = data['stock_transactions'] as List;

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Products: ${products.length}'),
                Text('Shops: ${shops.length}'),
                Text('Deliveries: ${deliveries.length}'),
                Text('Stock Transactions: ${transactions.length}'),
                const SizedBox(height: 16),
                const Text(
                  'Storage: Local SQLite Database',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }
}