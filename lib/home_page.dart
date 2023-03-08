import 'package:chess_collections/debug_constants.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

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
        child: Text(
          game.toString(),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}
