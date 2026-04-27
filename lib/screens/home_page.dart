import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Tela home protegida, acessível apenas após autenticação bem-sucedida.
///
/// Exibe informações do usuário autenticado obtidas a partir dos claims
/// do ID Token JWT retornado pelo Keycloak.
///
/// A proteção desta rota é garantida pelo [AppRouter] que redireciona
/// usuários não autenticados para a [LoginPage].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure App'),
        centerTitle: true,
        actions: [
          // Botão de logout na barra de navegação
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return IconButton(
                icon: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed:
                    authProvider.isLoading ? null : () => _confirmLogout(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cabeçalho de boas-vindas ──
                  _buildWelcomeHeader(context, user.name),

                  const SizedBox(height: 32),

                  // ── Card com informações do usuário ──
                  _buildUserInfoCard(context, authProvider),

                  const SizedBox(height: 24),

                  // ── Informações de segurança da sessão ──
                  _buildSessionInfo(context),

                  const SizedBox(height: 32),

                  // ── Botão de logout ──
                  _buildLogoutButton(context, authProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser!;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informações do usuário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Nome
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'Nome',
              value: user.name.isNotEmpty ? user.name : '—',
            ),
            const SizedBox(height: 12),

            // E-mail
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'E-mail',
              value: user.email.isNotEmpty ? user.email : '—',
              trailing: user.emailVerified
                  ? Tooltip(
                      message: 'E-mail verificado',
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Username
            _buildInfoRow(
              context,
              icon: Icons.alternate_email,
              label: 'Usuário',
              value: user.username.isNotEmpty ? user.username : '—',
            ),

            // Roles (se houver)
            if (user.realmRoles.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRolesRow(context, user.realmRoles),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolesRow(BuildContext context, List<String> roles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Roles',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: roles
                    .map(
                      (role) => Chip(
                        label: Text(
                          role,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sessão autenticada via Keycloak com tokens armazenados '
              'de forma segura no dispositivo.',
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return OutlinedButton.icon(
      onPressed: authProvider.isLoading
          ? null
          : () => _confirmLogout(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      icon: const Icon(Icons.logout),
      label: const Text(
        'Sair',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Exibe um diálogo de confirmação antes de realizar o logout.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do aplicativo'),
        content: const Text(
          'Deseja encerrar sua sessão? Você precisará fazer login novamente '
          'para acessar o aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
