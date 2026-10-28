import 'package:flutter/material.dart';

class ExpressionEditor extends StatefulWidget {
  const ExpressionEditor({super.key, required this.expression});

  final String expression;

  @override
  State<ExpressionEditor> createState() => _ExpressionEditorState();
}

class _ExpressionEditorState extends State<ExpressionEditor> {
  late final TextEditingController editor;

  @override
  void initState() {
    super.initState();
    editor = TextEditingController(text: widget.expression);
    editor.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editor.text.length,
    );
  }

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit calculation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('expression-editor'),
              controller: editor,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              maxLength: 480,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: 'e.g. sin(30) + 2^3',
                helperText: 'Use . for decimals. Functions use parentheses.',
                helperMaxLines: 8,
              ),
              onSubmitted: (_) => Navigator.pop(context, editor.text),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, editor.text),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
