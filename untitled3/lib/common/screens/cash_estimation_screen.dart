import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import '../../common/project_context.dart';

/// Cash Estimation Screen - Simple Expense Tracker
/// Allows users to add individual expenses and see total cost breakdown
class CashEstimationScreen extends StatefulWidget {
  const CashEstimationScreen({super.key});

  @override
  State<CashEstimationScreen> createState() => _CashEstimationScreenState();
}

class _CashEstimationScreenState extends State<CashEstimationScreen> {
  final _expenseNameController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _flatCostController = TextEditingController();
  final _constructedFloorsController = TextEditingController();
  bool _isOwner = false;
  bool _checkingRole = true;
  List<Map<String, dynamic>> _expenses = [];
  double _flatCost = 0.0;
  int _constructedFloors = 1;
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadExpenses();
  }

  @override
  void dispose() {
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _flatCostController.dispose();
    _constructedFloorsController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isOwner = false;
        _checkingRole = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'] ?? '';
        setState(() {
          _isOwner = role == 'owner' || role == 'ownerClient';
          _checkingRole = false;
        });
      } else {
        setState(() {
          _isOwner = false;
          _checkingRole = false;
        });
      }
    } catch (e) {
      setState(() {
        _isOwner = false;
        _checkingRole = false;
      });
    }
  }

  Future<void> _loadExpenses() async {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('cash_estimation')
          .doc('expenses')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
          _constructedFloors = data['constructedFloors'] ?? 1;
          _flatCost = (data['flatCost'] ?? 0.0).toDouble();
        });
        
        // Update controllers
        _constructedFloorsController.text = _constructedFloors.toString();
        if (_flatCost > 0) {
          _flatCostController.text = _flatCost.toString();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExpenses() async {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('cash_estimation')
          .doc('expenses')
          .set({
        'expenses': _expenses,
        'constructedFloors': _constructedFloors,
        'flatCost': _flatCost,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expenses: $e')),
        );
      }
    }
  }

  void _addExpense() {
    final name = _expenseNameController.text.trim();
    final amountText = _expenseAmountController.text.trim();

    if (name.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _expenses.add({
        'name': name,
        'amount': amount,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    });

    _expenseNameController.clear();
    _expenseAmountController.clear();
    _saveExpenses();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense added successfully')),
    );
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((expense) => expense['id'] == id);
    });
    _saveExpenses();
  }

  double get _totalExpenses {
    return _expenses.fold(0.0, (total, expense) => total + (expense['amount'] as double));
  }

  double get _oneFlatCost {
    if (_constructedFloors <= 0) return 0.0;
    return _totalExpenses / _constructedFloors;
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cash Estimation'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cash Estimation'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Owner Access Only',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cash estimation is only available to project owners.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cash Estimation'),
          backgroundColor: Colors.white.withValues(alpha: 0.55),
          elevation: 0,
        ),
        body: const Center(
          child: Text('No active project selected'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Estimation'),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const Text(
                    '1. Add all your expenses (cement, steel, labor, etc.)\n'
                    '2. Enter the number of flats in your building\n'
                    '3. Click Calculate to see cost per flat\n'
                    '4. Optionally enter selling price to see profit/loss',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'How to Use',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildAddExpenseCard(),
                  const SizedBox(height: 16),
                  _buildExpensesList(),
                  const SizedBox(height: 16),
                  _buildCostCalculationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: const Color(0xFF374151),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Expense Summary',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  if (_expenses.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_expenses.length} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAmountRow('Total Expenses', _totalExpenses, Colors.red, isTotal: true),
              if (_expenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Add more expenses above or calculate cost per flat below',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostCalculationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.calculate_outlined, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text(
                    'Cost Calculation',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Total Expenses Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '₹${_formatAmount(_totalExpenses)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF136DEC),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Floor Input Section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _constructedFloorsController,
                      decoration: InputDecoration(
                        labelText: 'Number of Flats',
                        hintText: 'Enter total flats',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.7),
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        setState(() {
                          _constructedFloors = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_constructedFloors > 0 && _totalExpenses > 0) {
                        setState(() {
                          // Trigger recalculation
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cost calculated!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter valid number of flats and add expenses')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Calculate'),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Calculation Results
              if (_constructedFloors > 0 && _totalExpenses > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cost per Flat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '₹${_formatAmount(_oneFlatCost)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'For $_constructedFloors flat${_constructedFloors == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '₹${_formatAmount(_totalExpenses)} ÷ $_constructedFloors',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Profit/Loss Section (Optional)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _flatCostController,
                        decoration: InputDecoration(
                          labelText: 'Selling Price per Flat (Optional)',
                          hintText: 'Enter selling price',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.7),
                          prefixIcon: const Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {
                            _flatCost = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                if (_flatCost > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_flatCost - _oneFlatCost) >= 0 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_flatCost - _oneFlatCost) >= 0 
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profit/Loss per Flat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '₹${_formatAmount(_flatCost - _oneFlatCost)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: (_flatCost - _oneFlatCost) >= 0 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (_flatCost - _oneFlatCost) >= 0 ? 'Profit' : 'Loss',
                              style: TextStyle(
                                fontSize: 14,
                                color: (_flatCost - _oneFlatCost) >= 0 
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            Text(
                              '₹${_formatAmount(_flatCost)} - ₹${_formatAmount(_oneFlatCost)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter Number of Flats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add expenses above, then enter the number of flats to calculate cost per flat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: const Color(0xFF374151),
          ),
        ),
        Text(
          '₹${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAddExpenseCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.add_circle_outline, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _expenseNameController,
                decoration: InputDecoration(
                  labelText: 'Expense Name',
                  hintText: 'e.g., Cement, Steel, Labor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expenseAmountController,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No Expenses Added',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first expense above to start tracking costs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text(
                    'Expenses List',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(_expenses.length, (index) {
                final expense = _expenses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '₹${_formatAmount(expense['amount'])}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF136DEC),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeExpense(expense['id']),
                        tooltip: 'Delete expense',
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i > 0) {
        buf.write(',');
      } else if (count > 3 && (count - 3) % 2 == 0 && i > 0) {
        buf.write(',');
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
