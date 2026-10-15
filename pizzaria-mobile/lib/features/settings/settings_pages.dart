import 'package:flutter/material.dart';

import '../../core/settings/app_settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: controller.themeMode,
                    onChanged: (value) => controller.setThemeMode(value!),
                    title: const Text('Usar configuração do aparelho'),
                    secondary: const Icon(Icons.brightness_auto_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: controller.themeMode,
                    onChanged: (value) => controller.setThemeMode(value!),
                    title: const Text('Tema claro'),
                    secondary: const Icon(Icons.light_mode_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: controller.themeMode,
                    onChanged: (value) => controller.setThemeMode(value!),
                    title: const Text('Tema escuro'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Localidade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Fuso horário'),
                subtitle: const Text(AppSettingsController.timezone),
              ),
            ),
            const SizedBox(height: 24),
            Text('Privacidade', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacidade e LGPD'),
                subtitle: Text(controller.privacyConsentAccepted
                    ? 'Consentimento registrado neste aparelho.'
                    : 'Revise como seus dados são utilizados.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivacyPage(controller: controller),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({required this.controller, super.key});

  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e LGPD')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Icon(Icons.shield_outlined, size: 56),
          const SizedBox(height: 16),
          Text('Como tratamos seus dados',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Usamos seus dados para criar sua conta, autenticar o acesso, '
            'processar pedidos, entregar produtos e permitir o acompanhamento '
            'do atendimento. Não armazenamos dados de cartão no aplicativo.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Você pode solicitar informações, correção ou exclusão dos seus '
            'dados pelos canais de atendimento da pizzaria, respeitadas as '
            'obrigações legais de guarda de informações.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: controller.privacyConsentAccepted
                ? null
                : () async {
                    await controller.acceptPrivacyConsent();
                    if (context.mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.check),
            label: Text(controller.privacyConsentAccepted
                ? 'Consentimento registrado'
                : 'Aceitar e continuar'),
          ),
        ],
      ),
    );
  }
}
