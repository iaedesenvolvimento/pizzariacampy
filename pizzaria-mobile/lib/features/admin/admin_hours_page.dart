import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminHoursPage extends StatefulWidget {
  const AdminHoursPage({super.key});

  @override
  State<AdminHoursPage> createState() => _AdminHoursPageState();
}

class _AdminHoursPageState extends State<AdminHoursPage> {
  static const _days = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
  final _closed = List<bool>.filled(7, false);
  final _open = List<TimeOfDay>.filled(7, const TimeOfDay(hour: 18, minute: 0));
  final _close = List<TimeOfDay>.filled(7, const TimeOfDay(hour: 23, minute: 0));
  AdminApiClient? _adminApi;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    _adminApi = AdminApiClient(
        ApiClient(config: AppConfig.fromEnvironment()), storage);
    try {
      final response = await _adminApi!.get('/admin/hours');
      if (response is List<dynamic>) {
        for (final value in response.whereType<Map<String, dynamic>>()) {
          final day = value['weekday'] as int?;
          if (day == null || day < 0 || day > 6) continue;
          _closed[day] = value['is_closed'] as bool? ?? false;
          _open[day] = _parseTime(value['open_time']?.toString()) ?? _open[day];
          _close[day] = _parseTime(value['close_time']?.toString()) ?? _close[day];
        }
      }
    } catch (_) {
      _message = 'Não foi possível carregar os horários.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save(int day) async {
    try {
      await _adminApi!.put(
        '/admin/hours/$day',
        body: {'open_time': _formatTime(_open[day]), 'close_time': _formatTime(_close[day]), 'is_closed': _closed[day]},
      );
      if (mounted) setState(() => _message = '${_days[day]} salvo.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível salvar o horário.');
    }
  }

  Future<void> _pickTime(int day, bool opening) async {
    final selected = await showTimePicker(context: context, initialTime: opening ? _open[day] : _close[day]);
    if (selected == null) return;
    setState(() => (opening ? _open : _close)[day] = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horários da loja')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_message!)),
              ...List.generate(7, (day) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(_days[day]), subtitle: Text(_closed[day] ? 'Fechado' : '${_formatTime(_open[day])} às ${_formatTime(_close[day])}'), value: !_closed[day], onChanged: (value) => setState(() => _closed[day] = !value)),
                    if (!_closed[day]) Row(children: [Expanded(child: OutlinedButton(onPressed: () => _pickTime(day, true), child: Text('Abre ${_formatTime(_open[day])}'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => _pickTime(day, false), child: Text('Fecha ${_formatTime(_close[day])}')))]),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _save(day), child: const Text('Salvar'))),
                  ])))),
            ]),
    );
  }

  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 18, minute: int.tryParse(parts[1]) ?? 0);
  }
}
