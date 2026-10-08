import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/export_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _jsonTextController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _jsonTextController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isProcessing = true);
    try {
      final summary = await ref
          .read(backupControllerProvider.notifier)
          .createBackup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup created (${summary.totalRecords} records across ${summary.tableCounts.length} tables)',
          ),
          backgroundColor: Colors.green.shade800,
          action: summary.filePath != null
              ? SnackBarAction(
                  label: 'Share',
                  textColor: Colors.white,
                  onPressed: () {
                    final file = File(summary.filePath!);
                    ref.read(shareServiceProvider).shareBackupFile(file);
                  },
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareDatabaseFile() async {
    setState(() => _isProcessing = true);
    try {
      final backupFile = await ref
          .read(backupServiceProvider)
          .exportDatabaseFile();

      if (!mounted) return;

      await ref
          .read(shareServiceProvider)
          .shareBackupFile(backupFile, subject: 'Garage SQLite Database File');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export SQLite database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRestoreFromJsonDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup JSON content below. WARNING: Restoring will overwrite all current local data with the backup records.',
              style: TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jsonTextController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Confirm Restore',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final content = _jsonTextController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final result = await ref
          .read(backupControllerProvider.notifier)
          .restoreFromJsonString(content);

      if (!mounted) return;

      _jsonTextController.clear();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Successful'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyBackupJsonToClipboard() async {
    setState(() => _isProcessing = true);
    try {
      final json = await ref
          .read(backupServiceProvider)
          .exportBackupJsonString();
      await Clipboard.setData(ClipboardData(text: json));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup JSON copied to clipboard.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupSummary = ref.watch(backupControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing backup operation...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Offline Data Safety',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your data is stored securely on your local device. Regularly creating backups protects your business records, invoices, and stock history.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Backup',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.cloud_upload_outlined),
                        ),
                        title: const Text('Export JSON Backup'),
                        subtitle: const Text(
                          'Creates a structured backup file of all customers, parts, invoices & expenses.',
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: _handleCreateBackup,
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text('Export'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.copy_outlined),
                        ),
                        title: const Text('Copy Backup JSON'),
                        subtitle: const Text(
                          'Copy full backup text to clipboard',
                        ),
                        trailing: TextButton.icon(
                          onPressed: _copyBackupJsonToClipboard,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.storage_outlined),
                        ),
                        title: const Text('Export SQLite Database File'),
                        subtitle: const Text(
                          'Exports raw .sqlite database file to share via WhatsApp/Drive.',
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: _handleShareDatabaseFile,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (backupSummary != null) ...[
                  const Text(
                    'Last Backup Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generated: ${backupSummary.exportDate}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Total Records: ${backupSummary.totalRecords}'),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: backupSummary.tableCounts.entries
                                .map(
                                  (e) =>
                                      Chip(label: Text('${e.key}: ${e.value}')),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Restore Database',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.restore),
                    ),
                    title: const Text('Restore from JSON Backup'),
                    subtitle: const Text(
                      'Re-import and validate previously exported backup data.',
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _handleRestoreFromJsonDialog,
                      child: const Text('Restore'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
