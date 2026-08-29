import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/vpn_service.dart';

void main() {
  runApp(const TehranVpnApp());
}

class TehranVpnApp extends StatelessWidget {
  const TehranVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minimal VPN',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        primaryColor: const Color(0xFF00E676),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VpnService _vpnService = VpnService();
  final TextEditingController _subController = TextEditingController();
  
  V2RayStatus _v2rayStatus = V2RayStatus();
  bool _isConnected = false;
  bool _isLoading = false;
  VpnConfigModel? _selectedConfig;
  List<VpnConfigModel> _configList = [];

  @override
  void initState() {
    super.initState();
    _initVpn();
  }

  Future<void> _initVpn() async {
    await _vpnService.initV2Ray((status) {
      setState(() {
        _v2rayStatus = status;
        _isConnected = status.state == 'CONNECTED';
      });
    });

    final prefs = await SharedPreferences.getInstance();
    String? savedSub = prefs.getString('saved_sub_url');
    if (savedSub != null && savedSub.isNotEmpty) {
      _subController.text = savedSub;
      _loadSubscription(savedSub);
    }
  }

  Future<void> _loadSubscription(String url) async {
    setState(() => _isLoading = true);
    List<VpnConfigModel> fetched = await _vpnService.fetchSubscription(url);
    setState(() {
      _configList = fetched;
      if (_configList.isNotEmpty) {
        _selectedConfig = _configList.first;
      }
      _isLoading = false;
    });
  }

  void _toggleConnect() async {
    if (_selectedConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا لینک سابسکریپشن را وارد کنید')),
      );
      return;
    }

    if (_isConnected) {
      await _vpnService.disconnect();
    } else {
      await _vpnService.connect(_selectedConfig!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TEHRAN VPN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link_rounded, color: Color(0xFF00E676)),
            onPressed: () => _showSubscriptionDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildSubscriptionCard(),
              const SizedBox(height: 20),
              _buildServerSelector(),
              const Spacer(),
              _buildConnectButton(),
              const Spacer(),
              _buildMetricsRow(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('وضعیت اشتراک', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('فعال', style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('حجم مصرفی', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('۱۸.۲ GB / ۵۰ GB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.36,
            backgroundColor: Colors.white10,
            color: const Color(0xFF00E676),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector() {
    return InkWell(
      onTap: () => _showServerListBottomSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.dns_rounded, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedConfig?.name ?? 'انتخاب سرور / کانفیگ',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return GestureDetector(
      onTap: _toggleConnect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF16181E),
          boxShadow: [
            BoxShadow(
              color: _isConnected ? const Color(0xFF00E676).withOpacity(0.25) : Colors.black45,
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: _isConnected ? const Color(0xFF00E676) : Colors.white12,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_settings_new_rounded,
              size: 56,
              color: _isConnected ? const Color(0xFF00E676) : Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              _isConnected ? 'CONNECTED' : 'DISCONNECTED',
              style: TextStyle(
                color: _isConnected ? const Color(0xFF00E676) : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricItem(Icons.network_ping_rounded, 'Ping', _isConnected ? '${_v2rayStatus.duration} ms' : '--'),
          Container(width: 1, height: 26, color: Colors.white10),
          _metricItem(Icons.arrow_downward_rounded, 'Download', _isConnected ? '${(_v2rayStatus.download / 1024).toStringAsFixed(1)} KB/s' : '--'),
          Container(width: 1, height: 26, color: Colors.white10),
          _metricItem(Icons.arrow_upward_rounded, 'Upload', _isConnected ? '${(_v2rayStatus.upload / 1024).toStringAsFixed(1)} KB/s' : '--'),
        ],
      ),
    );
  }

  Widget _metricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ورود لینک سابسکریپشن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _subController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF0D0E12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _loadSubscription(_subController.text.trim());
                },
                child: const Text('دریافت کانفیگ‌ها', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServerListBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لیست سرورها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _configList.length,
                itemBuilder: (context, index) {
                  final config = _configList[index];
                  final isSelected = _selectedConfig == config;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? const Color(0xFF00E676).withOpacity(0.08) : Colors.transparent,
                    leading: Icon(Icons.shield_outlined, color: isSelected ? const Color(0xFF00E676) : Colors.grey),
                    title: Text(config.name, style: TextStyle(fontSize: 13, color: isSelected ? const Color(0xFF00E676) : Colors.white)),
                    onTap: () {
                      setState(() {
                        _selectedConfig = config;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
