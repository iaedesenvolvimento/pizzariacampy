import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../cart/cart_controller.dart';
import '../../settings/settings_pages.dart';
import '../../menu/presentation/menu_pages.dart';

class AuthGate extends StatelessWidget {
  const AuthGate(
      {required this.controller,
      required this.cartController,
      required this.settingsController,
      super.key});

  final AuthController controller;
  final CartController cartController;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.status == AuthStatus.loading) {
          return const _LoadingPage();
        }
        if (controller.isAuthenticated) {
          return MenuHomePage(
              authController: controller,
              cartController: cartController,
              settingsController: settingsController);
        }
        return LoginPage(
            controller: controller, settingsController: settingsController);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage(
      {required this.controller, required this.settingsController, super.key});

  final AuthController controller;
  final AppSettingsController settingsController;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Entrar',
      subtitle: 'Peça sua pizza favorita com praticidade.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s'))
              ],
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: _requiredEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Informe sua senha.' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouteNames.recovery),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            AuthErrorMessage(controller: widget.controller),
            const SizedBox(height: 8),
            AuthSubmitButton(
              label: 'Entrar',
              isSubmitting: widget.controller.status == AuthStatus.submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RegisterPage(
                  controller: widget.controller,
                  settingsController: widget.settingsController,
                ),
              )),
              child: const Text('Criar uma conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage(
      {required this.controller, required this.settingsController, super.key});

  final AuthController controller;
  final AppSettingsController settingsController;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _privacyAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Criar conta',
      subtitle: 'Salve seus dados para finalizar o pedido.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Informe seu nome.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s'))
              ],
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: _requiredEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (value) => value != null && value.length >= 8
                  ? null
                  : 'Use pelo menos 8 caracteres.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmationController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'As senhas não coincidem.',
            ),
            AuthErrorMessage(controller: widget.controller),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _privacyAccepted,
              onChanged: (value) =>
                  setState(() => _privacyAccepted = value ?? false),
              title: const Text('Aceito o tratamento dos meus dados'),
              subtitle: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PrivacyPage(
                        controller: widget.settingsController,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() => _privacyAccepted =
                        widget.settingsController.privacyConsentAccepted);
                  }
                },
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                child: const Text('Leia a política de privacidade e a LGPD.'),
              ),
            ),
            const SizedBox(height: 16),
            AuthSubmitButton(
              label: 'Criar conta',
              isSubmitting: widget.controller.status == AuthStatus.submitting,
              onPressed: _privacyAccepted
                  ? () async {
                      await widget.settingsController.acceptPrivacyConsent();
                      await _submit();
                    }
                  : null,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Já tenho uma conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await widget.controller.requestPasswordRecovery(_emailController.text);
    if (success && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Recuperar senha',
      subtitle: _sent
          ? 'Instruções enviadas para o seu e-mail.'
          : 'Informe seu e-mail para continuar.',
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Enviamos as instruções para ${_emailController.text.trim()}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Abra o e-mail e toque no link para criar uma nova senha. '
                  'Se não encontrar a mensagem, confira a pasta de spam ou lixo eletrônico.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar para entrar'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s'))
                    ],
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: _requiredEmail,
                  ),
                  AuthErrorMessage(controller: widget.controller),
                  const SizedBox(height: 16),
                  AuthSubmitButton(
                    label: 'Enviar instruções',
                    isSubmitting:
                        widget.controller.status == AuthStatus.submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizzaria Campy'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              await controller.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text('Olá, ${controller.user?.name ?? ''}!')),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold(
      {required this.title,
      required this.subtitle,
      required this.child,
      super.key});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            child,
          ],
        ),
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton(
      {required this.label,
      required this.isSubmitting,
      required this.onPressed,
      super.key});

  final String label;
  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Aguarde...'),
              ],
            )
          : Text(label),
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.errorMessage;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}

class AppRouteNames {
  static const home = '/home';
  static const login = '/login';
  static const register = '/register';
  static const recovery = '/recovery';
}

String? _requiredEmail(String? value) {
  final email = value?.trim() ?? '';
  final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  if (!validEmail) return 'Informe um e-mail válido, como nome@dominio.com.';
  return null;
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
