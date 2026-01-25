import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../services/tool_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/tool_transaction_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'tool_qr_scanner_screen.dart';

/// Return Tool Screen - Manager Only
class ReturnToolScreen extends StatefulWidget {
  const ReturnToolScreen({super.key});

  @override
  State<ReturnToolScreen> createState() => _ReturnToolScreenState();
}

class _ReturnToolScreenState extends State<ReturnToolScreen> {
  String? _scannedToolId;
  File? _qrImage;
  ToolTransactionModel? _activeTransaction;
  String? _selectedCondition;
  bool _isLoading = false;
  bool _isScanning = false;

  final List<Map<String, String>> _conditions = [
    {'value': 'GOOD', 'label': 'Good Condition'},
    {'value': 'DAMAGED', 'label': 'Damaged'},
  ];

  Future<void> _scanQrCode() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const ToolQrScannerScreen()),
      );

      if (result != null && mounted) {
        final toolId = result['toolId'] as String;
        final qrImage = result['qrImage'] as File;

        // Fetch active transaction
        final transaction = await ToolService.getActiveTransaction(toolId);

        if (transaction == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active transaction found for this tool'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isScanning = false;
          });
          return;
        }

        setState(() {
          _scannedToolId = toolId;
          _qrImage = qrImage;
          _activeTransaction = transaction;
          _isScanning = false;
        });
      } else {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning QR: $e')),
        );
      }
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _submitReturn() async {
    if (_scannedToolId == null || _qrImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan tool QR code first')),
      );
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select tool condition')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);

      // Upload QR image to Cloudinary
      String? qrImageUrl;
      if (isOnline) {
        qrImageUrl = await CloudinaryService.uploadImage(_qrImage!);
        if (qrImageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload QR image. Saving offline.')),
            );
          }
        }
      }

      Map<String, dynamic> result;

      if (isOnline && qrImageUrl != null) {
        // Online: Save to Firestore
        result = await ToolService.returnTool(
          toolId: _scannedToolId!,
          condition: _selectedCondition!,
          returnQrImageUrl: qrImageUrl,
        );
      } else {
        // Offline: Save to Hive
        result = await ToolService.returnToolOffline(
          toolId: _scannedToolId!,
          condition: _selectedCondition!,
          returnQrImageUrl: qrImageUrl ?? 'offline_pending',
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOnline ? 'Tool returned successfully' : 'Tool returned (offline - will sync)'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to return tool'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Tool'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Scan QR
              _buildSectionCard(
                title: 'Step 1: Scan Tool QR',
                child: Column(
                  children: [
                    if (_scannedToolId != null && _activeTransaction != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tool Scanned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Tool ID: $_scannedToolId',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('Borrowed by', _activeTransaction!.workerName),
                            const SizedBox(height: 8),
                            _buildInfoRow('Mobile', _activeTransaction!.mobileNumber),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Borrowed on',
                              '${_activeTransaction!.borrowedAt.day}/${_activeTransaction!.borrowedAt.month}/${_activeTransaction!.borrowedAt.year}',
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Scan the QR code on the tool to return',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isScanning || _isLoading ? null : _scanQrCode,
                      icon: _isScanning
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: Text(_scannedToolId != null ? 'Scan Again' : 'Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF136DEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Step 2: Condition Check
              if (_activeTransaction != null)
                _buildSectionCard(
                  title: 'Step 2: Check Tool Condition',
                  child: Column(
                    children: _conditions.map((condition) {
                      return RadioListTile<String>(
                        title: Text(condition['label']!),
                        value: condition['value']!,
                        groupValue: _selectedCondition,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCondition = value;
                                });
                              },
                        activeColor: const Color(0xFF136DEC),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              if (_activeTransaction != null) const SizedBox(height: 24),

              // Submit Button
              if (_activeTransaction != null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Return',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
