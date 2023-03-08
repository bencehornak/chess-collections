import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ChessBoardController controller = ChessBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Demo'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChessBoard(
            controller: controller,
            boardColor: BoardColor.orange,
            boardOrientation: PlayerColor.white,
          ),
          const Expanded(
            child: ChessMoveHistory(),
          ),
        ],
      ),
    );
  }
}

class ChessMoveHistory extends StatelessWidget {
  const ChessMoveHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child:
            Text('1. e4 e5 2. Nc3 Nf6 3. f4 exf4', textAlign: TextAlign.start),
      ),
    );
  }
}
