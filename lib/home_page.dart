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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _generateRows(),
        ),
      ),
    );
  }

  List<Widget> _generateRows() {
    final List<Widget> rows = [];
    game.traverse((board, lastMove, nextMoves) {
      Chess boardCopy = board.copy();
      rows.add(ChessMove(
          onTap: () => onChessPositionChosen(boardCopy),
          color: board.turn,
          moveNumber: board.move_number,
          san: lastMove.san));
    });
    return rows;
  }
}

class ChessMove extends StatelessWidget {
  static const _moveNumberTextStyle = TextStyle(fontWeight: FontWeight.bold);

  final ch.Color color;
  final int moveNumber;
  final String san;
  final GestureTapCallback? onTap;

  const ChessMove({
    required this.color,
    required this.moveNumber,
    required this.san,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ch.Color lastMoveColor =
        color == ch.Color.WHITE ? ch.Color.BLACK : ch.Color.WHITE;
    // The moveNumber is increased before black in the chess lib. It is
    // probably a bug.
    final fixedMoveNumber =
        lastMoveColor == ch.Color.BLACK ? moveNumber - 1 : moveNumber;

    final dots = lastMoveColor == ch.Color.WHITE ? '.' : '...';
    final halfMoveNumber =
        (fixedMoveNumber - 1) * 2 + (lastMoveColor == ch.Color.BLACK ? 1 : 0);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: (12 * halfMoveNumber).toDouble()),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$fixedMoveNumber$dots',
                style: _moveNumberTextStyle,
              ),
            ),
            Text(san),
          ],
        ),
      ),
    );
  }
}
