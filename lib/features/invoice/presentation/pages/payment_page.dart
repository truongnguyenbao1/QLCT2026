import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice.dart';
import '../bloc/invoice_bloc.dart';

class PaymentPage extends StatefulWidget {
  final String invoiceId;

  const PaymentPage({super.key, required this.invoiceId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _paymentMethod = 'Chuyển khoản';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán hóa đơn'),
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.pop(); // Go back to invoice details
          } else if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          Invoice? invoice;
          if (state is InvoicesLoaded) {
            invoice = state.invoices.firstWhere((i) => i.id == widget.invoiceId, orElse: () => throw Exception('Not found'));
          } else if (state is InvoiceActionSuccess && state.invoices != null) {
            invoice = state.invoices!.firstWhere((i) => i.id == widget.invoiceId, orElse: () => throw Exception('Not found'));
          }

          if (invoice == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Sample VietQR string format (this should be generated properly using VietQR standard API or format)
          // format: https://vietqr.net/portal/qr-format
          // Placeholder QR data
          final qrData = 'VIETQR_PAYMENT_INFO_${invoice.id}_${invoice.totalAmount}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Thanh toán phòng ${invoice.roomNumber}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kỳ hóa đơn: ${invoice.billingPeriod}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Số tiền cần thanh toán',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.formatCurrency(invoice.totalAmount),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 32),
                        const Text('Quét mã VietQR để thanh toán'),
                        const SizedBox(height: 16),
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Text('Phương thức: '),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: ['Chuyển khoản', 'Tiền mặt', 'Momo'].map((method) {
                          return DropdownMenuItem(value: method, child: Text(method));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.read<InvoiceBloc>().add(
                        MarkInvoicePaidEvent(
                          invoiceId: invoice!.id,
                          paymentMethod: _paymentMethod,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Xác nhận đã thanh toán'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
