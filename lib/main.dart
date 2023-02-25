import 'package:flutter/material.dart';
import 'package:flutter_stateless_chessboard/models/board_color.dart';
import 'package:flutter_stateless_chessboard/widgets/chessboard.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Chessboard(
            size: 300,
            fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            onMove: (move) {
              // optional
              // TODO: process the move
              // ignore: avoid_print
              print("move from ${move.from} to ${move.to}");
            },
            orientation: BoardColor.BLACK, // optional
            lightSquareColor:
                const Color.fromRGBO(240, 217, 181, 1), // optional
            darkSquareColor: const Color.fromRGBO(181, 136, 99, 1), // optional
          ),
        ),
      ),
    ),
  );
}
