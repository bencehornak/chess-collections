import 'package:chess_collections/debug_constants.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as ch;
import 'package:logging/logging.dart';

final _logger = Logger('home_page');

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameWithVariations? game;
  ChessBoardController controller = ChessBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChessCollectionsAppBar(
        onPgnImportPressed: _onPgnImportPressed,
      ),
      body: game == null
          ? const PgnLoading()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChessBoard(
                  controller: controller,
                  boardColor: BoardColor.orange,
                  boardOrientation: PlayerColor.white,
                ),
                Expanded(
                  child: ChessMoveHistory(
                    game: game!,
                    onChessPositionChosen: _onChessPositionChosen,
                  ),
                ),
              ],
            ),
    );
  }

  void _onChessPositionChosen(Chess board) {
    setState(() {
      controller = ChessBoardController.fromGame(board);
    });
  }

  void _onPgnImportPressed() async {
    final importedGame = await _showImportDialogPgn();
    _logger.info(
        'The imported games are (choosing the first game):\n$importedGame');
    setState(() {
      game = importedGame?[0];
    });
  }

  Future<List<GameWithVariations>?> _showImportDialogPgn() {
    return showDialog<List<GameWithVariations>>(
      context: context,
      builder: (BuildContext context) => const PgnImportDialog(),
    );
  }
}

class PgnImportDialog extends StatefulWidget {
  const PgnImportDialog({Key? key}) : super(key: key);

  @override
  State<PgnImportDialog> createState() => _PgnImportDialogState();
}

class _PgnImportDialogState extends State<PgnImportDialog> {
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
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text('Import'),
          onPressed: () {
            try {
              final game = PgnReader.fromString(_controller.text).parse();
              Navigator.of(context).pop(game);
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
}

class ChessCollectionsAppBar extends AppBar {
  ChessCollectionsAppBar({
    required VoidCallback onPgnImportPressed,
    Key? key,
  }) : super(
          title: const Text('Chess Collections'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.file_open),
              onPressed: onPgnImportPressed,
            )
          ],
          key: key,
        );
}

class PgnLoading extends StatelessWidget {
  const PgnLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

class ChessMoveHistory extends StatelessWidget {
  final GameWithVariations game;
  final void Function(Chess board) onChessPositionChosen;

  const ChessMoveHistory({
    required this.game,
    required this.onChessPositionChosen,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _generateRows(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _generateRows() {
    final List<Widget> rows = [];
    game.traverse((board, node) {
      if (node.rootNode) return; // Root node has no visualization

      Chess boardCopy = board.copy();
      rows.add(ChessMove(
          onTap: () => onChessPositionChosen(boardCopy), move: node.move!));
    });
    return rows;
  }
}

class ChessMove extends StatelessWidget {
  static const _moveNumberTextStyle = TextStyle(fontWeight: FontWeight.bold);

  final AnnotatedMove move;
  final GestureTapCallback? onTap;

  const ChessMove({
    required this.move,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
            left: (12 * (move.totalHalfMoveNumber - 1)).toDouble()),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                move.moveNumberIndicator,
                style: _moveNumberTextStyle,
              ),
            ),
            Text(move.san),
          ],
        ),
      ),
    );
  }
}
