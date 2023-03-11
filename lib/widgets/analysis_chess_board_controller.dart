import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class AnalysisChessBoardState {
  GameNode? currentNode;
  Chess? board;
  ChessBoardController chessBoardController;

  AnalysisChessBoardState() : chessBoardController = ChessBoardController();
}

class AnalysisChessBoardController
    extends ValueNotifier<AnalysisChessBoardState> {
  GameNode? get currentNode => value.currentNode;
  Chess? get board => value.board;
  ChessBoardController get chessBoardController => value.chessBoardController;

  AnalysisChessBoardController() : super(AnalysisChessBoardState());

  void goTo(GameNode node, Chess board) {
    value.currentNode = node;
    value.board = board;
    value.chessBoardController = ChessBoardController.fromGame(board);
    notifyListeners();
  }
}
