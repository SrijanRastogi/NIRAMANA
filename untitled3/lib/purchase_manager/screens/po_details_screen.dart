import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/purchase_order_model.dart';
import 'package:intl/intl.dart';

/// PO Details Screen - View and manage purchase order details
class PODetailsScreen extends StatelessWidget {
  final PurchaseOrderModel po;

  const PODetailsScreen({super.key, required this.po});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(po.poNumber ?? 'Purchase Order'),
        backgroundColor: const Color(0xFF136DEC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildVendorSection(),
            const SizedBox(height: 24),
            _buildItemsSection(),
            const SizedBox(height: 24),
            _buildSummarySection(),
            if (po.notes != null && po.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotesSection(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (po.status) {
      case 'PO_CREATED':
        statusColor = Colors.blue;
        statusText = 'Active - Awaiting Delivery';
        statusIcon = Icons.pending_actions;
        break;
      case 'GRN_CONFIRMED':
        statusColor = Colors.green;
        statusText = 'Completed - Goods Received';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = po.status;
        statusIcon = Icons.help;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor, statusColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(statusIcon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vendor Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF136DEC),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Vendor Name', po.vendorName),
              _buildDetailRow('GSTIN', po.vendorGSTIN),
              if (po.vendorContact != null)
                _buildDetailRow('Contact', po.vendorContact!),
              if (po.vendorAddress != null)
                _buildDetailRow('Address', po.vendorAddress!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PO Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF136DEC),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Material')),
                    DataColumn(label: Text('Qty'), numeric: true),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Rate'), numeric: true),
                    DataColumn(label: Text('Amount'), numeric: true),
                  ],
                  rows: po.items
                      .map((item) => DataRow(cells: [
                            DataCell(Text(item.materialName)),
                            DataCell(Text(item.quantity.toStringAsFixed(2))),
                            DataCell(Text(item.unit)),
                            DataCell(Text('₹${item.rate.toStringAsFixed(2)}')),
                            DataCell(Text('₹${item.amount.toStringAsFixed(2)}')),
                          ]))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final gstRate = po.gstType == 'IGST' ? 0.18 : 0.09;
    final gstAmount = po.totalAmount * gstRate;
    final totalWithGST = po.totalAmount + gstAmount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF136DEC),
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Base Amount', '₹${po.totalAmount.toStringAsFixed(2)}'),
              _buildSummaryRow(
                '${po.gstType == 'IGST' ? 'IGST' : 'CGST+SGST'} (${(gstRate * 100).toStringAsFixed(0)}%)',
                '₹${gstAmount.toStringAsFixed(2)}',
              ),
              const Divider(height: 16),
              _buildSummaryRow(
                'Total Amount',
                '₹${totalWithGST.toStringAsFixed(2)}',
                isBold: true,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Created', DateFormat('dd MMM yyyy, hh:mm a').format(po.createdAt)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF136DEC),
                ),
              ),
              const SizedBox(height: 12),
              Text(po.notes!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: isBold ? const Color(0xFF136DEC) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
