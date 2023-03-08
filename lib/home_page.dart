import 'package:chess_collections/debug_constants.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as ch;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GameWithVariations? game;
  ChessBoardController controller = ChessBoardController();

  @override
  void initState() {
    game = PgnReader.fromString(DebugConstants.examplePGN).parse()[0];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Demo'),
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
                  ),
                ),
              ],
            ),
    );
  }
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

  const ChessMoveHistory({required this.game, Key? key}) : super(key: key);

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
      rows.add(ChessMove(
          color: board.turn, moveNumber: board.move_number, san: lastMove.san));
    });
    return rows;
  }
}

class ChessMove extends StatelessWidget {
  static const _moveNumberTextStyle = TextStyle(fontWeight: FontWeight.bold);

  final ch.Color color;
  final int moveNumber;
  final String san;
  const ChessMove({
    required this.color,
    required this.moveNumber,
    required this.san,
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
    return Padding(
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
    );
  }
}
