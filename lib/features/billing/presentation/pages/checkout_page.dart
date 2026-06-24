import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../domain/entities/bill.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessing = false;

  void _completeOrder(ShopLoaded shopState) {
    setState(() => _isProcessing = true);
    context.read<BillingBloc>().add(
          SaveBillEvent(
            shopName: shopState.shop.name,
            phone: shopState.shop.phoneNumber,
          ),
        );
  }

  void _printReceipt(ShopLoaded shopState, BillingState billingState) {
    context.read<BillingBloc>().add(
          PrintReceiptEvent(
            shopName: shopState.shop.name,
            address1: shopState.shop.addressLine1,
            address2: shopState.shop.addressLine2,
            phone: shopState.shop.phoneNumber,
            footer: shopState.shop.footerText,
          ),
        );
    
    // Also save the transaction to history automatically
    context.read<BillingBloc>().add(
          SaveBillEvent(
            shopName: shopState.shop.name,
            phone: shopState.shop.phoneNumber,
          ),
        );
  }

  Future<void> _sharePdfBill(ShopLoaded shopState, BillingState billingState) async {
    // Generate a temporary Bill entity to pass to helper
    final bill = Bill(
      id: 'TEMP_INVOICE',
      dateTime: DateTime.now(),
      items: billingState.cartItems.map((e) => BillItem(
        productName: e.product.name,
        price: e.product.price,
        quantity: e.quantity,
      )).toList(),
      totalAmount: billingState.totalAmount,
      shopName: shopState.shop.name,
      shopPhone: shopState.shop.phoneNumber,
    );

    await PdfHelper.sharePdf(
      bill: bill,
      address1: shopState.shop.addressLine1,
      address2: shopState.shop.addressLine2,
      upiId: shopState.shop.upiId,
      footerText: shopState.shop.footerText,
    );

    // Also save the transaction to history automatically
    if (mounted) {
      context.read<BillingBloc>().add(
            SaveBillEvent(
              shopName: shopState.shop.name,
              phone: shopState.shop.phoneNumber,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Checkout Summary',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt printed successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state.saveBillSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order saved to History successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.go('/');
            }
            if (state.error != null) {
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                if (shopState is! ShopLoaded) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final upiId = shopState.shop.upiId;
                final shopName = shopState.shop.name;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // Clean Solid Receipt Table Container
                            GlassContainer(
                              borderRadius: 16,
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[200]!),
                              padding: EdgeInsets.zero,
                              child: Table(
                                border: TableBorder(
                                  horizontalInside: BorderSide(color: Colors.grey[100]!),
                                ),
                                children: [
                                  // Header row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                    ),
                                    children: [
                                      _buildHeaderCell('Product Name', TextAlign.left),
                                      _buildHeaderCell('Price', TextAlign.right),
                                      _buildHeaderCell('Total', TextAlign.right),
                                    ],
                                  ),
                                  // Items rows
                                  ...billingState.cartItems.map((item) {
                                    return TableRow(
                                      children: [
                                        _buildDataCell(
                                          '${item.quantity} x ${item.product.name}',
                                          TextAlign.left,
                                        ),
                                        _buildDataCell(
                                          '₹${item.product.price.toStringAsFixed(2)}',
                                          TextAlign.right,
                                          isSubtitle: true,
                                        ),
                                        _buildDataCell(
                                          '₹${item.total.toStringAsFixed(2)}',
                                          TextAlign.right,
                                          isBold: true,
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // QR payment card (if UPI exists)
                            if (upiId.isNotEmpty) ...[
                              GlassContainer(
                                borderRadius: 16,
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[200]!),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Scan to Pay via UPI',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey[200]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      width: 160,
                                      height: 160,
                                      child: PrettyQrView.data(
                                        data: 'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 120), // Spacing for bottom floating panel
                          ],
                        ),
                      ),
                    ),

                    // Bottom Actions Bar (Clean White)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Summary row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GRAND TOTAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                '₹${billingState.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Primary Complete Action
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 4,
                                shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                              onPressed: _isProcessing ? null : () => _completeOrder(shopState),
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline, size: 22),
                              label: Text(
                                _isProcessing ? 'Saving Order...' : 'Complete & Save Order',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Secondary Printing & Sharing Row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _printReceipt(shopState, billingState),
                                  icon: const Icon(Icons.print, size: 18),
                                  label: const Text(
                                    'Print Bill',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _sharePdfBill(shopState, billingState),
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text(
                                    'Share PDF',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align, {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}
