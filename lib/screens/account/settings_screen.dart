import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true, marketing = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(children: [
    SwitchListTile(title: const Text('Order notifications'), subtitle: const Text('Updates about your orders'), value: notifications, onChanged: (v) => setState(() => notifications = v)),
    SwitchListTile(title: const Text('Promotions and offers'), subtitle: const Text('News about art supplies and sales'), value: marketing, onChanged: (v) => setState(() => marketing = v)),
    const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy Policy'), trailing: Icon(Icons.chevron_right)),
    const ListTile(leading: Icon(Icons.description_outlined), title: Text('Terms of Service'), trailing: Icon(Icons.chevron_right)),
  ]));
}
