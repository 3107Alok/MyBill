import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/bill.dart';
import '../bloc/billing_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Dispatch LoadBillHistoryEvent to ensure the state has the latest history
    context.read<BillingBloc>().add(LoadBillHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<BillingBloc, BillingState>(
          builder: (context, billingState) {
            final bills = billingState.billHistory;
            
            // Filter based on search query
            final filteredBills = bills.where((bill) {
              final query = _searchQuery.toLowerCase();
              final matchesId = bill.id.toLowerCase().contains(query);
              final matchesItemName = bill.items.any((item) =>
                  item.productName.toLowerCase().contains(query));
              return matchesId || matchesItemName;
            }).toList();

            // Calculate stats
            final now = DateTime.now();
            final todayBills = bills.where((b) =>
                b.dateTime.year == now.year &&
                b.dateTime.month == now.month &&
                b.dateTime.day == now.day);
            final todaySales = todayBills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);

            final thirtyDaysAgo = now.subtract(const Duration(days: 30));
            final monthlyBills = bills.where((b) => b.dateTime.isAfter(thirtyDaysAgo));
            final monthlySales = monthlyBills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);

            return Column(
              children: [
                const SizedBox(height: 16),
                
                // Summary Stats Row (Clean light cards)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Today's Sales",
                          value: '₹${todaySales.toStringAsFixed(1)}',
                          icon: Icons.today,
                          accentColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: "30-Day Sales",
                          value: '₹${monthlySales.toStringAsFixed(1)}',
                          icon: Icons.calendar_month,
                          accentColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Clean Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassContainer(
                    borderRadius: 12,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Search by Bill ID or Item Name...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // History List
                Expanded(
                  child: filteredBills.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                          itemCount: filteredBills.length,
                          itemBuilder: (context, idx) {
                            final bill = filteredBills[idx];
                            return _buildBillCard(bill);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return GlassContainer(
      borderRadius: 16,
      color: Colors.white,
      border: Border.all(color: Colors.grey[200]!),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Try checking spelling or ID' : 'Completed sales will appear here.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Bill bill) {
    final timeStr = DateFormat('hh:mm a').format(bill.dateTime);
    final dateStr = DateFormat('dd MMM yyyy').format(bill.dateTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showBillDetails(bill),
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          borderRadius: 16,
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill #${bill.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bill.items.length} items  •  $timeStr, $dateStr',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${bill.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillDetails(Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final upiId = context.read<ShopBloc>().state is ShopLoaded
            ? (context.read<ShopBloc>().state as ShopLoaded).shop.upiId
            : '';
        final address1 = context.read<ShopBloc>().state is ShopLoaded
            ? (context.read<ShopBloc>().state as ShopLoaded).shop.addressLine1
            : '';
        final address2 = context.read<ShopBloc>().state is ShopLoaded
            ? (context.read<ShopBloc>().state as ShopLoaded).shop.addressLine2
            : '';
        final footerText = context.read<ShopBloc>().state is ShopLoaded
            ? (context.read<ShopBloc>().state as ShopLoaded).shop.footerText
            : '';

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return GlassContainer(
              borderRadius: 24,
              blur: 20,
              color: const Color(0xFAFAFAFA), // Crisp clean off-white background
              border: Border.all(color: Colors.grey[200]!),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bill Receipt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDeleteBill(bill),
                        )
                      ],
                    ),
                  ),
                  
                  Divider(color: Colors.grey[200]),
                  
                  // Receipt Detail List
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      children: [
                        // Paper receipt style container
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Shop details header
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      bill.shopName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (address1.isNotEmpty)
                                      Text(
                                        address1,
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    if (address2.isNotEmpty)
                                      Text(
                                        address2,
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    if (bill.shopPhone.isNotEmpty)
                                      Text(
                                        'Phone: ${bill.shopPhone}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                      ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '------------------------------------------',
                                      style: TextStyle(color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              Text('Bill ID: ${bill.id}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                              Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(bill.dateTime)}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                              const SizedBox(height: 10),
                              const Text(
                                '------------------------------------------',
                                style: TextStyle(color: Colors.black38),
                              ),
                              const SizedBox(height: 10),
                              
                              // Table Header
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                                  ),
                                  Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                                  SizedBox(width: 12),
                                  Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                                  SizedBox(width: 12),
                                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 8),
                              
                              // Table items
                              ...bill.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(item.productName, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                      const SizedBox(width: 12),
                                      Text('₹${item.price.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                      const SizedBox(width: 12),
                                      Text('₹${item.total.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                );
                              }),
                              
                              const SizedBox(height: 12),
                              const Text(
                                '------------------------------------------',
                                style: TextStyle(color: Colors.black38),
                              ),
                              const SizedBox(height: 10),
                              
                              // Grand Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                  Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons Footer (Light styling)
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.share, size: 20),
                            label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await PdfHelper.sharePdf(
                                bill: bill,
                                address1: address1,
                                address2: address2,
                                upiId: upiId,
                                footerText: footerText,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(ctx).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.print, size: 20),
                            label: const Text('Print Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              context.read<BillingBloc>().add(PrintReceiptEvent(
                                shopName: bill.shopName,
                                address1: address1,
                                address2: address2,
                                phone: bill.shopPhone,
                                footer: footerText,
                              ));
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Print job sent to Bluetooth helper...'),
                                  behavior: SnackBarBehavior.floating,
                                )
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBill(Bill bill) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Bill', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete Bill #${bill.id.substring(0, 8).toUpperCase()}? This action cannot be undone.',
            style: const TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                context.read<BillingBloc>().add(DeleteBillEvent(bill.id));
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bill deleted successfully'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
