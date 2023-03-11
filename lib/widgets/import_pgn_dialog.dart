import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../util/debug_constants.dart';

final _logger = Logger('import_pgn_dialog');

class ImportPgnDialog extends StatefulWidget {
  const ImportPgnDialog({Key? key}) : super(key: key);

  @override
  State<ImportPgnDialog> createState() => _ImportPgnDialogState();
}

class _ImportPgnDialogState extends State<ImportPgnDialog> {
  late TextEditingController _controller;
  dynamic error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import PGN'),
      content: SizedBox(
        width: 400,
        height: 600,
        child: TextField(
          controller: _controller,
          minLines: null,
          maxLines: null,
          expands: true,
          decoration: error != null
              ? InputDecoration(
                  errorText: error.toString(),
                )
              : null,
        ),
      ),
      actions: <Widget>[
        if (kDebugMode)
          TextButton(
            child: const Text('Use advanced.pgn'),
            onPressed: () => _parseAndPop(context, DebugConstants.advancedPGN),
          ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Import'),
          onPressed: () {
            try {
              _parseAndPop(context, _controller.text);
            } catch (error, stackTrace) {
              _logger.warning('Error while parsing PGN', error, stackTrace);
              setState(() {
                this.error = error;
              });
            }
          },
        ),
      ],
    );
  }

  void _parseAndPop(BuildContext context, String pgnString) {
    final game = PgnReader.fromString(pgnString).parse();
    Navigator.of(context).pop(game);
  }
}
