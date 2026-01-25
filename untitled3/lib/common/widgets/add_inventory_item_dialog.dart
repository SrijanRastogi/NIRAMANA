import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../services/inventory_service.dart';

/// Dialog for adding new inventory items
class AddInventoryItemDialog extends StatefulWidget {
  final String projectId;

  const AddInventoryItemDialog({
    super.key,
    required this.projectId,
  });

  @override
  State<AddInventoryItemDialog> createState() => _AddInventoryItemDialogState();
}

class _AddInventoryItemDialogState extends State<AddInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'CEMENT';
  String _selectedUnit = 'KG';
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);

  @override
  void initState() {
    super.initState();
    // Set default values
    _minStockController.text = '10';
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await InventoryService.addInventoryItem(
        projectId: widget.projectId,
        itemName: _itemNameController.text.trim(),
        category: _selectedCategory,
        quantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
        minStockLevel: double.parse(_minStockController.text),
        unitPrice: _unitPriceController.text.isNotEmpty 
            ? double.parse(_unitPriceController.text) 
            : null,
        supplier: _supplierController.text.trim().isNotEmpty 
            ? _supplierController.text.trim() 
            : null,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Inventory item added successfully!'),
            backgroundColor: Color(0xFF10B981),
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
          content: Text('❌ Error adding item: $e'),
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
            height: MediaQuery.of(context).size.height * 0.8,
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
                      colors: [primary, primary.withValues(alpha: 0.8)],
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
                      const Icon(
                        Icons.add_box_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add Inventory Item',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Item Name
                          _buildTextField(
                            controller: _itemNameController,
                            label: 'Item Name *',
                            hint: 'e.g., Portland Cement, Steel Rods',
                            icon: Icons.inventory_2_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Item name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category and Unit Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Category *',
                                  value: _selectedCategory,
                                  items: InventoryService.getPredefinedCategories(),
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value!);
                                  },
                                  icon: Icons.category_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdown(
                                  label: 'Unit *',
                                  value: _selectedUnit,
                                  items: InventoryService.getPredefinedUnits(),
                                  onChanged: (value) {
                                    setState(() => _selectedUnit = value!);
                                  },
                                  icon: Icons.straighten_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quantity and Min Stock Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _quantityController,
                                  label: 'Initial Quantity *',
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
                                    if (quantity == null || quantity < 0) {
                                      return 'Enter valid quantity';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _minStockController,
                                  label: 'Min Stock Level *',
                                  hint: '10',
                                  icon: Icons.warning_amber_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Min stock level is required';
                                    }
                                    final minStock = double.tryParse(value);
                                    if (minStock == null || minStock < 0) {
                                      return 'Enter valid min stock level';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Unit Price (Optional)
                          _buildTextField(
                            controller: _unitPriceController,
                            label: 'Unit Price (Optional)',
                            hint: 'Price per ${_selectedUnit.toLowerCase()}',
                            icon: Icons.currency_rupee_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Supplier (Optional)
                          _buildTextField(
                            controller: _supplierController,
                            label: 'Supplier (Optional)',
                            hint: 'e.g., ABC Construction Materials',
                            icon: Icons.business_outlined,
                          ),
                          const SizedBox(height: 16),

                          // Location (Optional)
                          _buildTextField(
                            controller: _locationController,
                            label: 'Storage Location (Optional)',
                            hint: 'e.g., Warehouse A, Site Storage',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),

                          // Description (Optional)
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: 'Additional notes about this item',
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
                                  onPressed: _isLoading ? null : _addItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
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
                                          'Add Item',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
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
                item.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}