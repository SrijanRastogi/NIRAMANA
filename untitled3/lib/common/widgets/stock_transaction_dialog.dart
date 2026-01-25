import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';

/// Dialog for stock in/out transactions
class StockTransactionDialog extends StatefulWidget {
  final InventoryItemModel item;
  final bool isStockIn;

  const StockTransactionDialog({
    super.key,
    required this.item,
    required this.isStockIn,
  });

  @override
  State<StockTransactionDialog> createState() => _StockTransactionDialogState();
}

class _StockTransactionDialogState extends State<StockTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _receiptController = TextEditingController();

  String _selectedReason = 'PURCHASE';
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);

  @override
  void initState() {
    super.initState();
    // Set default reason based on transaction type
    _selectedReason = widget.isStockIn ? 'PURCHASE' : 'USAGE';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  List<String> get _availableReasons {
    if (widget.isStockIn) {
      return ['PURCHASE', 'DELIVERY', 'RETURN', 'ADJUSTMENT'];
    } else {
      return ['USAGE', 'DAMAGE', 'THEFT', 'WASTAGE', 'TRANSFER', 'ADJUSTMENT'];
    }
  }

  String get _reasonDisplay {
    switch (_selectedReason) {
      case 'PURCHASE':
        return 'Material Purchase';
      case 'DELIVERY':
        return 'Material Delivery';
      case 'USAGE':
        return 'Used in Construction';
      case 'DAMAGE':
        return 'Damaged/Broken';
      case 'THEFT':
        return 'Theft/Missing';
      case 'RETURN':
        return 'Returned to Supplier';
      case 'TRANSFER':
        return 'Transfer to Site';
      case 'WASTAGE':
        return 'Material Wastage';
      case 'ADJUSTMENT':
        return 'Stock Adjustment';
      default:
        return _selectedReason;
    }
  }

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = double.parse(_quantityController.text);
      final quantityChange = widget.isStockIn ? quantity : -quantity;

      final result = await InventoryService.updateInventoryQuantity(
        itemId: widget.item.id,
        projectId: widget.item.projectId,
        quantityChange: quantityChange,
        reason: _selectedReason,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        unitPrice: _unitPriceController.text.isNotEmpty 
            ? double.parse(_unitPriceController.text) 
            : null,
        supplier: _supplierController.text.trim().isNotEmpty 
            ? _supplierController.text.trim() 
            : null,
        receiptNumber: _receiptController.text.trim().isNotEmpty 
            ? _receiptController.text.trim() 
            : null,
        referenceType: 'MANUAL',
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Stock ${widget.isStockIn ? 'added' : 'removed'} successfully!\n'
              'New quantity: ${result['newQuantity'].toStringAsFixed(2)} ${widget.item.unit}',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${result['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing transaction: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionColor = widget.isStockIn 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [transactionColor, transactionColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isStockIn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isStockIn ? 'Stock In' : 'Stock Out',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.item.itemName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Stock Info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Stock',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '${widget.item.quantity.toStringAsFixed(2)} ${widget.item.unit}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(int.parse(widget.item.statusColor.substring(1), radix: 16) + 0xFF000000),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.status.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Quantity and Reason Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _quantityController,
                                  label: 'Quantity *',
                                  hint: '0',
                                  icon: Icons.numbers_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final quantity = double.tryParse(value);
                                    if (quantity == null || quantity <= 0) {
                                      return 'Enter valid quantity';
                                    }
                                    if (!widget.isStockIn && quantity > widget.item.quantity) {
                                      return 'Cannot remove more than available stock';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Reason *',
                                  value: _selectedReason,
                                  items: _availableReasons,
                                  onChanged: (value) {
                                    setState(() => _selectedReason = value!);
                                  },
                                  icon: Icons.category_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Unit Price (for stock in)
                          if (widget.isStockIn) ...[
                            _buildTextField(
                              controller: _unitPriceController,
                              label: 'Unit Price (Optional)',
                              hint: 'Price per ${widget.item.unit.toLowerCase()}',
                              icon: Icons.currency_rupee_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Supplier (for stock in)
                          if (widget.isStockIn) ...[
                            _buildTextField(
                              controller: _supplierController,
                              label: 'Supplier (Optional)',
                              hint: 'e.g., ABC Construction Materials',
                              icon: Icons.business_outlined,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Receipt Number (for stock in)
                          if (widget.isStockIn) ...[
                            _buildTextField(
                              controller: _receiptController,
                              label: 'Receipt/Invoice Number (Optional)',
                              hint: 'e.g., INV-2024-001',
                              icon: Icons.receipt_outlined,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Notes
                          _buildTextField(
                            controller: _notesController,
                            label: 'Notes (Optional)',
                            hint: 'Additional details about this transaction',
                            icon: Icons.notes_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _processTransaction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: transactionColor,
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
                                      : Text(
                                          widget.isStockIn ? 'Add Stock' : 'Remove Stock',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                _getReasonDisplayText(item),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getReasonDisplayText(String reason) {
    switch (reason) {
      case 'PURCHASE':
        return 'Material Purchase';
      case 'DELIVERY':
        return 'Material Delivery';
      case 'USAGE':
        return 'Used in Construction';
      case 'DAMAGE':
        return 'Damaged/Broken';
      case 'THEFT':
        return 'Theft/Missing';
      case 'RETURN':
        return 'Returned to Supplier';
      case 'TRANSFER':
        return 'Transfer to Site';
      case 'WASTAGE':
        return 'Material Wastage';
      case 'ADJUSTMENT':
        return 'Stock Adjustment';
      default:
        return reason.replaceAll('_', ' ');
    }
  }
}