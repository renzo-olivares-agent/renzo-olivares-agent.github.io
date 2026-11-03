import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// The last error Flutter reported, shown on screen so the bug is visible
/// without opening the browser console.
final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

void main() {
  final FlutterExceptionHandler? defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    lastError.value = details.exceptionAsString();
    defaultOnError?.call(details);
  };
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final TextEditingController _controller = TextEditingController(
    text: 'The first line of text\nA second line\nThe third line\nThe last line',
  );

  @override
  void initState() {
    super.initState();
    _controller.selection = const TextSelection.collapsed(offset: 4);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _caretPosition(TextEditingValue value) {
    final int offset = value.selection.extentOffset;
    if (offset < 0) {
      return 'no caret';
    }
    final String before = value.text.substring(0, offset);
    final int line = '\n'.allMatches(before).length + 1;
    final int column = offset - (before.lastIndexOf('\n') + 1) + 1;
    return 'line $line, column $column';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'This multiline TextField is inside a SelectionArea. Click in it and '
                'press Shift+Up or Shift+Down to extend the selection by a line. '
                'Without the fix, Flutter reports a TypeError, shown in red below.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (BuildContext context, TextEditingValue value, Widget? child) {
                  return Text('Caret: ${_caretPosition(value)}');
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String?>(
                valueListenable: lastError,
                builder: (BuildContext context, String? error, Widget? child) {
                  return Text(
                    error == null ? 'Errors: none' : 'Last error: $error',
                    style: TextStyle(color: error == null ? null : Colors.red),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
