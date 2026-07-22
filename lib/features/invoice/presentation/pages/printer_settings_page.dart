import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/thermal_printer_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({Key? key}) : super(key: key);

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final ThermalPrinterService _printerService = getIt<ThermalPrinterService>();
  
  List<BluetoothInfo> _devices = [];
  bool _isConnecting = false;
  String _connectedMac = '';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetDevices();
  }

  Future<void> _checkPermissionsAndGetDevices() async {
    // Yêu cầu quyền Bluetooth (cho Android 12+)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Location thường cần thiết cho việc quét bluetooth ở các bản Android cũ
    ].request();

    bool connected = await _printerService.isConnected;
    
    // Nếu chưa lấy được danh sách, ta gọi plugin để lấy các thiết bị đã pair
    final devices = await _printerService.getPairedDevices();
    
    setState(() {
      _devices = devices;
      // Dùng tên placeholder cho kết nối hiện tại vì plugin không trả về tên thiết bị đang kết nối dễ dàng
      _connectedMac = connected ? 'Đã kết nối' : '';
    });
  }

  Future<void> _connect(String macAddress) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      bool result = await _printerService.connect(macAddress);
      if (result) {
        setState(() {
          _connectedMac = macAddress;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kết nối máy in thành công!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kết nối thất bại. Vui lòng kiểm tra lại máy in.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    bool result = await _printerService.disconnect();
    if (result) {
      setState(() {
        _connectedMac = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ngắt kết nối máy in')),
        );
      }
    }
  }

  Future<void> _testPrint() async {
    if (_connectedMac.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kết nối máy in trước')),
      );
      return;
    }

    try {
      final bytes = await _printerService.generateInvoiceTicket(
        propertyName: 'TEST NHA TRO',
        roomName: 'P.101',
        month: 7,
        year: 2026,
        totalAmount: 3500000,
        invoiceId: 'TEST-123',
        paymentQrData: 'https://example.com',
      );
      
      bool printed = await _printerService.printTicket(bytes);
      if (printed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang in test...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt máy in (Bluetooth)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionsAndGetDevices,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isConnecting) const LinearProgressIndicator(),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _connectedMac.isNotEmpty ? Icons.print : Icons.print_disabled,
                  color: _connectedMac.isNotEmpty ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trạng thái kết nối:'),
                      Text(
                        _connectedMac.isNotEmpty ? 'Đã kết nối ($_connectedMac)' : 'Chưa kết nối',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _connectedMac.isNotEmpty ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_connectedMac.isNotEmpty)
                  ElevatedButton(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Ngắt kết nối', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
          if (_connectedMac.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: _testPrint,
                icon: const Icon(Icons.receipt),
                label: const Text('In Test Hóa Đơn'),
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Danh sách máy in đã ghép nối (Paired Devices)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('Không tìm thấy máy in nào đã ghép nối.'))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name),
                        subtitle: Text(device.macAdress),
                        trailing: ElevatedButton(
                          onPressed: _isConnecting || _connectedMac == device.macAdress
                              ? null
                              : () => _connect(device.macAdress),
                          child: const Text('Kết nối'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
