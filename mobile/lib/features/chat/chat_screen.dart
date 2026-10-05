import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../app/app_scope.dart';
import '../../app/format.dart';
import '../../app/wording.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../auth/require_sign_in.dart';
import '../home/home_shell.dart';

class _Turn {
  _Turn.user(this.text) : answer = null;
  _Turn.assistant(ChatAnswer this.answer) : text = null;

  final String? text;
  ChatAnswer? answer;
}

/// "What worked for me": recalls what the user took before for a symptom, or looks up a medicine.
/// Never prescribes; anything else is declined by the server (S5, S8).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One person's answers must not stay on screen for the next after sign-out.
    if (!AppScope.of(context).signedIn) _turns.clear();
  }

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _busy) return;
    final api = AppScope.api(context);
    // Recall and medicine lookup both need to know who is asking (S11). The typed message is kept.
    if (!await requireSignIn(context) || !mounted) return;
    setState(() {
      _turns.add(_Turn.user(message));
      _busy = true;
      _input.clear();
    });
    try {
      final answer = await api.chat(message);
      if (mounted) setState(() => _turns.add(_Turn.assistant(answer)));
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget userBubble(String message) => Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
            child: Text(message, style: text.bodyLarge?.copyWith(color: scheme.onPrimary)),
          ),
        );

    Widget assistantBubble(ChatAnswer answer) => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(answer.text, style: text.bodyLarge),
                const SizedBox(height: 8),
                // Every answer ends with the doctor-vs-app line (S8).
                Text(answer.footer, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        );

    Widget recordCard(RecalledMedicine m) => MedicineCard(
          name: m.name,
          selfAdded: false,
          dose: dotted([m.dose, m.frequency, m.duration]),
          meta: dotted([m.condition, m.prescriber, m.date == null ? null : prettyDate(m.date!)]),
          // Chat shows feedback as recorded and never asks for it; it is given on the prescription (S5).
          footer: m.feedback == null ? 'No feedback recorded' : 'Your feedback: ${feedbackLabel(m.feedback)}',
        );

    Widget generalInfoCard(ChatAnswer answer) => Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About ${answer.medicineName}', style: text.titleMedium),
                const SizedBox(height: 8),
                Text('Usually prescribed for', style: text.labelLarge),
                Text(answer.generalUsedFor!, style: text.bodyMedium),
                if (answer.generalStorage != null) ...[
                  const SizedBox(height: 8),
                  Text('How to keep it', style: text.labelLarge),
                  Text(answer.generalStorage!, style: text.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(answer.generalDisclaimer!, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        );

    List<Widget> answerWidgets(_Turn turn) {
      final answer = turn.answer!;
      if (answer.isEscalation) return [const Align(alignment: Alignment.centerLeft, child: EscalationCard())];
      return [
        assistantBubble(answer),
        if (answer.allergyMatch) const InfoBanner('This medicine matches an allergy you listed.'),
        if (answer.generalUsedFor != null) generalInfoCard(answer),
        for (final m in answer.medicines) recordCard(m),
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('What worked for me'), actions: const [AccountMenu()]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoBanner(doctorVsApp),
            const SizedBox(height: 8),
            Expanded(
              child: _turns.isEmpty
                  ? Center(
                      child: Text(
                        'Describe a minor symptom to see what you took for it before,\n'
                        'or type a medicine name to look it up.'
                        '${AppScope.of(context).signedIn ? '' : '\n\nYou will be asked to sign in when you send.'}',
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      controller: _scroll,
                      children: [
                        for (final turn in _turns)
                          for (final w in turn.text != null ? [userBubble(turn.text!)] : answerWidgets(turn))
                            Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
                        if (_busy) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _input,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'A symptom or a medicine name',
                counterText: '',
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send, color: scheme.primary),
                  tooltip: 'Send',
                  onPressed: _busy ? null : _send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
