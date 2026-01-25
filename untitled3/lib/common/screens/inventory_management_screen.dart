import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';
import '../../models/inventory_transaction_model.dart';
import '../project_context.dart';
import '../widgets/add_inventory_item_dialog.dart';
import '../widgets/stock_transaction_dialog.dart';

/// Inventory Management Screen - Comprehensive inventory tracking
/// Allows managers to track materials, supplies, and equipment
class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primary = Color(0xFF136DEC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectId = ProjectContext.activeProjectId;
    if (projectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Management'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            Text(
              ProjectContext.activeProjectName ?? 'Project',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5C5C5C),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddItemDialog(context, projectId),
            tooltip: 'Add Item',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Items', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Low Stock', icon: Icon(Icons.warning_amber_outlined)),
            Tab(text: 'Out of Stock', icon: Icon(Icons.error_outline)),
            Tab(text: 'Transactions', icon: Icon(Icons.history_outlined)),
          ],
          labelColor: primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: primary,
        ),
      ),
      body: Column(
        children: [
          _buildStatsHeader(projectId),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllItemsTab(projectId),
                _buildLowStockTab(projectId),
                _buildOutOfStockTab(projectId),
                _buildTransactionsTab(projectId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(String projectId) {
    return StreamBuilder<Map<String, int>>(
      stream: InventoryService.getInventoryStats(projectId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'totalItems': 0,
          'inStockItems': 0,
          'lowStockItems': 0,
          'outOfStockItems': 0,
        };

        return Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
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
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Items',
                        stats['totalItems']!,
                        Icons.inventory_2,
                        primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'In Stock',
                        stats['inStockItems']!,
                        Icons.check_circle,
                        const Color(0xFF10B981),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Low Stock',
                        stats['lowStockItems']!,
                        Icons.warning,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Out of Stock',
                        stats['outOfStockItems']!,
                        Icons.error,
                        const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search inventory items...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.7),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildAllItemsTab(String projectId) {
    return StreamBuilder<List<InventoryItemModel>>(
      stream: _searchQuery.isEmpty
          ? InventoryService.getProjectInventoryItems(projectId)
          : InventoryService.searchInventoryItems(projectId, _searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState(
            'No Items Found',
            _searchQuery.isEmpty
                ? 'Add your first inventory item to start tracking materials'
                : 'No items match your search criteria',
            Icons.inventory_2_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildInventoryItemCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildLowStockTab(String projectId) {
    return StreamBuilder<List<InventoryItemModel>>(
      stream: InventoryService.getLowStockItems(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState(
            'No Low Stock Items',
            'All items are adequately stocked',
            Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildInventoryItemCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildOutOfStockTab(String projectId) {
    return StreamBuilder<List<InventoryItemModel>>(
      stream: InventoryService.getOutOfStockItems(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _buildEmptyState(
            'No Out of Stock Items',
            'All items are in stock',
            Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildInventoryItemCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionsTab(String projectId) {
    return StreamBuilder<List<InventoryTransactionModel>>(
      stream: InventoryService.getRecentTransactions(projectId, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return _buildEmptyState(
            'No Transactions',
            'No inventory transactions recorded yet',
            Icons.history_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildInventoryItemCard(InventoryItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(item.statusColor.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.1),
                child: Text(
                  item.categoryIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: Text(
                item.itemName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (item.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${item.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(int.parse(item.statusColor.substring(1), radix: 16) + 0xFF000000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.status.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleItemAction(value, item),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'stock_in',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text('Stock In'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock_out',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444)),
                            SizedBox(width: 8),
                            Text('Stock Out'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF6B7280)),
                            SizedBox(width: 8),
                            Text('View History'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: Color(0xFF136DEC)),
                            SizedBox(width: 8),
                            Text('Edit Item'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(InventoryTransactionModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(transaction.typeColor.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.1),
                child: Text(
                  transaction.typeIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              title: Text(
                transaction.reasonDisplay,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.type == 'OUT' ? '-' : '+'}${transaction.quantity.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(int.parse(transaction.typeColor.substring(1), radix: 16) + 0xFF000000),
                    ),
                  ),
                  Text(
                    '${transaction.createdByName} • ${_formatDateTime(transaction.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  if (transaction.notes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Text(
                '${transaction.previousQuantity.toStringAsFixed(1)} → ${transaction.newQuantity.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemAction(String action, InventoryItemModel item) {
    switch (action) {
      case 'stock_in':
        _showStockTransactionDialog(item, true);
        break;
      case 'stock_out':
        _showStockTransactionDialog(item, false);
        break;
      case 'history':
        _showItemHistory(item);
        break;
      case 'edit':
        _showEditItemDialog(item);
        break;
    }
  }

  void _showAddItemDialog(BuildContext context, String projectId) {
    showDialog(
      context: context,
      builder: (context) => AddInventoryItemDialog(projectId: projectId),
    );
  }

  void _showStockTransactionDialog(InventoryItemModel item, bool isStockIn) {
    showDialog(
      context: context,
      builder: (context) => StockTransactionDialog(
        item: item,
        isStockIn: isStockIn,
      ),
    );
  }

  void _showItemHistory(InventoryItemModel item) {
    // Implementation for item history screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${item.itemName} History'),
          ),
          body: const Center(
            child: Text('Item history implementation goes here'),
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(InventoryItemModel item) {
    // Implementation for edit item dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Text('Edit ${item.itemName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}