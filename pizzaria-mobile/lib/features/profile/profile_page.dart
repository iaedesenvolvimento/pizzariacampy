import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.controller, super.key});

  final AuthController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.controller.user?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      _showMessage('Informe um nome válido.');
      return;
    }
    setState(() => _saving = true);
    final success = await widget.controller.updateProfile(name: name);
    if (!mounted) return;
    setState(() => _saving = false);
    _showMessage(success
        ? 'Perfil atualizado.'
        : widget.controller.errorMessage ??
            'Não foi possível atualizar o perfil.');
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || !mounted) return;
    setState(() => _saving = true);
    final success = await widget.controller.uploadProfilePhoto(
      bytes: file.bytes!,
      filename: file.name,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _showMessage(success
        ? 'Foto atualizada.'
        : widget.controller.errorMessage ??
            'Não foi possível atualizar a foto.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final user = widget.controller.user;
        return Scaffold(
          appBar: AppBar(title: const Text('Meu perfil')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const Icon(Icons.person_outline, size: 54)
                          : null,
                    ),
                    IconButton.filled(
                      tooltip: 'Alterar foto',
                      onPressed: _saving ? null : _pickPhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Dados pessoais',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'O e-mail é usado para acessar sua conta.',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _saveName,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
              ),
            ],
          ),
        );
      },
    );
  }
}
