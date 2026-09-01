import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../core/settings/locale_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';

/// Shows the signed-in agent's details and a sign-out action.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final agent = state is AuthAuthenticated ? state.agent : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: agent == null
          ? Center(child: Text(l10n.profileNotSignedIn))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: Text(
                          agent.firstName.isNotEmpty ? agent.firstName[0] : '?',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        agent.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _InfoTile(icon: Icons.badge_outlined, label: l10n.profileMatricule, value: agent.matricule),
                _InfoTile(icon: Icons.work_outline, label: l10n.profileRole, value: agent.role),
                _InfoTile(icon: Icons.map_outlined, label: l10n.profileRegion, value: agent.region),
                if (agent.phone != null && agent.phone!.isNotEmpty)
                  _InfoTile(icon: Icons.phone_outlined, label: l10n.profilePhone, value: agent.phone!),
                const SizedBox(height: 24),
                const _LanguageSelector(),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.profileSignOut),
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      // Return to the root (AuthGate), which now shows login.
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
    );
  }
}

/// Switches the app between French and Arabic.
///
/// Surveys carry both languages (the generator fills `label.fr` and `label.ar`),
/// but without this control the app stayed on its French default and the Arabic
/// half was invisible. Changing it also flips the whole app to RTL, because
/// `MaterialApp.locale` follows the same provider.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 12),
                Text(
                  // The pair is shown together on purpose: an agent looking for
                  // the language switch may not read the current language.
                  '${AppLocalizations.of(context).profileLanguage} / اللغة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(
                  value: AppLanguage.fr,
                  label: Text('Français'),
                ),
                ButtonSegment(
                  value: AppLanguage.ar,
                  label: Text('العربية'),
                ),
              ],
              selected: {current},
              onSelectionChanged: (selection) => ref
                  .read(localeControllerProvider.notifier)
                  .setLanguage(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
