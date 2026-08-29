import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VpnConfigModel {
  final String name;
  final String fullUrl;
  num ping;

  VpnConfigModel({required this.name, required this.fullUrl, this.ping = -1});
}

class VpnService {
  final FlutterV2ray flutterV2ray = FlutterV2ray();
  List<VpnConfigModel> configs = [];
  bool isInitialized = false;

  Future<void> initV2Ray(void Function(V2RayStatus status) onStatusChanged) async {
    if (!isInitialized) {
      await flutterV2ray.initializeV2Ray(
        onStatusChanged: onStatusChanged,
      );
      isInitialized = true;
    }
  }

  Future<List<VpnConfigModel>> fetchSubscription(String subUrl) async {
    try {
      final response = await http.get(Uri.parse(subUrl));
      if (response.statusCode == 200) {
        String rawData = response.body.trim();
        
        String decodedData;
        try {
          decodedData = utf8.decode(base64.decode(base64.normalize(rawData)));
        } catch (_) {
          decodedData = rawData;
        }

        List<String> lines = decodedData.split(RegExp(r'\r?\n'));
        configs.clear();

        for (var line in lines) {
          line = line.trim();
          if (line.isNotEmpty) {
            String name = 'Server ${configs.length + 1}';
            if (line.contains('#')) {
              name = Uri.decodeComponent(line.split('#').last);
            }
            configs.add(VpnConfigModel(name: name, fullUrl: line));
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_sub_url', subUrl);
      }
    } catch (e) {
      print("Error fetching subscription: $e");
    }
    return configs;
  }

  Future<int> getPing(String configUrl) async {
    try {
      final delay = await flutterV2ray.getConnectedServerDelay();
      return delay;
    } catch (_) {
      return -1;
    }
  }

  Future<void> connect(VpnConfigModel config) async {
    if (await flutterV2ray.requestPermission()) {
      V2RayURL v2rayURL = FlutterV2ray.parseFromURL(config.fullUrl);
      await flutterV2ray.startV2Ray(
        remark: config.name,
        config: v2rayURL.toShareUrl(),
        blockedApps: null,
        bypassSubnets: null,
        proxyOnly: false,
      );
    }
  }

  Future<void> disconnect() async {
    await flutterV2ray.stopV2ray();
  }
}
