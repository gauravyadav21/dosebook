import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/wording.dart';

/// Marks where a medicine came from. Self-added entries are never shown as prescribed (S7).
class SourceTag extends StatelessWidget {
  const SourceTag({super.key, required this.selfAdded});

  final bool selfAdded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selfAdded ? scheme.tertiaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        selfAdded ? 'Self-added' : 'From prescription',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selfAdded ? scheme.onTertiaryContainer : scheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

/// Short, persistent doctor-vs-app line (S8).
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

/// Fixed escalation wording. Never shown together with a medicine list (S5, S8).
class EscalationCard extends StatelessWidget {
  const EscalationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(escalationTitle, style: text.titleMedium?.copyWith(color: scheme.onErrorContainer)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(escalationBody, style: text.bodyMedium?.copyWith(color: scheme.onErrorContainer)),
          const SizedBox(height: 8),
          Text(emergencyLine, style: text.labelMedium?.copyWith(color: scheme.onErrorContainer)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              body,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon, small label and value: phone, registration number, availability.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                Text(value, style: text.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loads data for a screen. Every screen that shows server data goes through this, which gives it:
/// a spinner, an error message with retry, pull-to-refresh, a reload whenever the user's data changes
/// anywhere in the app, and a reload when the app comes back to the foreground.
/// The builder should return a scrollable (a ListView, or [ScrollableFill] around fixed content)
/// so that pull-to-refresh works.
class Loader<T> extends StatefulWidget {
  const Loader({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<Loader<T>> createState() => LoaderState<T>();
}

class LoaderState<T> extends State<Loader<T>> with WidgetsBindingObserver {
  T? _data;
  Object? _error;
  bool _loaded = false;
  int? _revision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs on first build and again each time the session reports a change.
    final revision = AppScope.of(context).revision;
    if (revision != _revision) {
      _revision = revision;
      reload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> reload() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_loaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: reload, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: reload,
      // Also react to lists nested inside tabs, not only a list directly below.
      notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical,
      child: widget.builder(context, _data as T, reload),
    );
  }
}

/// Makes fixed content (such as an empty state) fill the screen and still respond to pull-to-refresh.
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: child),
      ),
    );
  }
}

void showMessage(BuildContext context, Object message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$message')));
}

/// Runs an action and shows its error, if any, instead of failing silently. Returns true on success.
Future<bool> guarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, e);
    return false;
  }
}
