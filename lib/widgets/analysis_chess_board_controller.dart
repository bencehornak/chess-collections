import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:collection/collection.dart';
import 'package:chess/chess.dart' as ch;

class AnalysisChessBoardState {
  GameNode? currentNode;
  ChessBoardController chessBoardController;

  AnalysisChessBoardState() : chessBoardController = ChessBoardController();
}

class AnalysisChessBoardController
    extends ValueNotifier<AnalysisChessBoardState> {
  GameNode? get currentNode => value.currentNode;
  Chess? get board => value.chessBoardController.game;
  ChessBoardController get chessBoardController => value.chessBoardController;

  ch.State? _lastChessBoardState;

  AnalysisChessBoardController() : super(AnalysisChessBoardState());

  @override
  void dispose() {
    value.chessBoardController.dispose();
    super.dispose();
  }

  void goTo(GameNode node, Chess board) {
    value.currentNode = node;
    value.chessBoardController.dispose();
    value.chessBoardController = ChessBoardController.fromGame(board);
    value.chessBoardController.addListener(_onBoardChange);
    _lastChessBoardState = board.history.last;
    notifyListeners();
  }

  void _onBoardChange() {
    // If the user followed a line in the analysis, let's adjust currentNode to
    // the corresponding GameNode
    if (value.currentNode != null && board!.history.length >= 2) {
      final secondLastBoardState = board!.history[board!.history.length - 2];
      if (identical(_lastChessBoardState, secondLastBoardState)) {
        final children = value.currentNode!.children;
        final matchingContinuationNode = children.firstWhereOrNull(
            (child) => _movesEqual(child.move!, board!.history.last.move));
        if (matchingContinuationNode != null) {
          value.currentNode = matchingContinuationNode;
          _lastChessBoardState = board!.history.last;
          notifyListeners();
          return;
        }
      }
    }
    // Otherwise the user has diverged from the analysis, let's set the
    // currentNode to null
    value.currentNode = null;
    _lastChessBoardState = null;
    notifyListeners();
  }

  bool _movesEqual(Move a, Move b) {
    return a.color == b.color &&
        a.from == b.from &&
        a.to == b.to &&
        a.flags == b.flags &&
        a.piece == b.piece &&
        a.captured == b.captured &&
        a.promotion == b.promotion;
  }
}
