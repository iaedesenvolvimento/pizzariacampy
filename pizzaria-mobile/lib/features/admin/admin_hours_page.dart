import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminHoursPage extends StatefulWidget {
  const AdminHoursPage({super.key});

  @override
  State<AdminHoursPage> createState() => _AdminHoursPageState();
}

class _AdminHoursPageState extends State<AdminHoursPage> {
  static const _days = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  final _closed = List<bool>.filled(7, false);
  final _open = List<TimeOfDay>.filled(7, const TimeOfDay(hour: 18, minute: 0));
  final _close =
      List<TimeOfDay>.filled(7, const TimeOfDay(hour: 23, minute: 0));
  final _saving = List<bool>.filled(7, false);
  AdminApiClient? _adminApi;
  bool _loading = true;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final storage = await AppStorage.create();
      _adminApi = AdminApiClient(
          ApiClient(config: AppConfig.fromEnvironment()), storage);
      final response = await _adminApi!.get('/admin/hours');
      if (response is! List<dynamic>) throw const FormatException();
      for (final value in response.whereType<Map<String, dynamic>>()) {
        final day = value['weekday'] as int?;
        if (day == null || day < 0 || day > 6) continue;
        _closed[day] = value['is_closed'] as bool? ?? false;
        _open[day] = AdminBusinessHourPresentation.parseTime(
                value['open_time']?.toString()) ??
            _open[day];
        _close[day] = AdminBusinessHourPresentation.parseTime(
                value['close_time']?.toString()) ??
            _close[day];
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar os horários.';
        });
    }
  }

  Future<void> _save(int day) async {
    if (_adminApi == null || _saving[day]) return;
    if (!_closed[day] &&
        !AdminBusinessHourPresentation.isValidRange(_open[day], _close[day])) {
      setState(
          () => _message = 'O fechamento deve acontecer depois da abertura.');
      return;
    }
    setState(() {
      _saving[day] = true;
      _message = null;
    });
    try {
      await _adminApi!.put('/admin/hours/$day', body: {
        'open_time': _closed[day]
            ? null
            : '${AdminBusinessHourPresentation.formatTime(_open[day])}:00',
        'close_time': _closed[day]
            ? null
            : '${AdminBusinessHourPresentation.formatTime(_close[day])}:00',
        'is_closed': _closed[day],
      });
      if (mounted) setState(() => _message = '${_days[day]} atualizado.');
    } catch (_) {
      if (mounted)
        setState(() => _message =
            'Não foi possível salvar ${_days[day].toLowerCase()}. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving[day] = false);
    }
  }

  Future<void> _pickTime(int day, bool opening) async {
    final selected = await showTimePicker(
        context: context, initialTime: opening ? _open[day] : _close[day]);
    if (selected == null || !mounted) return;
    setState(() => (opening ? _open : _close)[day] = selected);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Horários de funcionamento',
      subtitle:
          'Configure os dias e horários em que a Pizzaria Campy recebe pedidos.',
      activeDestination: AdminDestinationId.hours,
      body: _loading
          ? const AdminLoadingState(label: 'Carregando horários')
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : LayoutBuilder(builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth > AdminBreakpoints.mediumMax ? 2 : 1;
                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(AdminSpacing.lg),
                      children: [
                        AdminPageHeader(
                          title: 'Horários de funcionamento',
                          subtitle:
                              'Configure os dias e horários em que a Pizzaria Campy recebe pedidos.',
                        ),
                        if (_message != null) ...[
                          Semantics(liveRegion: true, child: Text(_message!)),
                          const SizedBox(height: AdminSpacing.md),
                        ],
                        GridView.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: AdminSpacing.lg,
                          mainAxisSpacing: AdminSpacing.lg,
                          childAspectRatio: columns == 1 ? 0.95 : 1.45,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var day = 0; day < 7; day++)
                              AdminBusinessHourCard(
                                dayLabel: _days[day],
                                isClosed: _closed[day],
                                opening: _open[day],
                                closing: _close[day],
                                isToday: DateTime.now().weekday - 1 == day,
                                isSaving: _saving[day],
                                onToggle: (value) =>
                                    setState(() => _closed[day] = !value),
                                onPickOpening: () => _pickTime(day, true),
                                onPickClosing: () => _pickTime(day, false),
                                onSave: () => _save(day),
                              )
                          ],
                        ),
                      ],
                    ),
                  );
                }),
    );
  }
}
