import 'package:chess_collections/widgets/analysis_chess_board_node_notifier.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:collection/collection.dart';
import 'package:chess/chess.dart' as ch;

class AnalysisChessBoardState {
  ChessHalfMoveTree? game;
  ChessHalfMoveTreeNode? currentNode;
  ChessBoardController chessBoardController;
  ch.State? _lastChessBoardState;

  AnalysisChessBoardState() : chessBoardController = ChessBoardController();

  void _reset() {
    game = null;
    currentNode = null;
    chessBoardController.dispose();
    chessBoardController = ChessBoardController();
    _lastChessBoardState = null;
  }
}

class AnalysisChessBoardController
    extends ValueNotifier<AnalysisChessBoardState> {
  ChessHalfMoveTree? get game => value.game;
  ChessHalfMoveTreeNode? get currentNode => value.currentNode;
  Chess? get board => value.chessBoardController.game;
  ChessBoardController get chessBoardController => value.chessBoardController;

  bool _skipNextOnBoardChange = false;

  final Map<ChessHalfMoveTreeNode, AnalysisChessBoardNodeNotifier>
      _nodeNotifiers = {};

  AnalysisChessBoardController() : super(AnalysisChessBoardState());

  @override
  void dispose() {
    value.chessBoardController.dispose();
    _resetNodeNotifiers();
    super.dispose();
  }

  void loadGame(ChessHalfMoveTree? game) {
    value._reset();
    value.game = game;
    value.currentNode = game?.rootNode;
    _resetNodeNotifiers();
    if (game != null) {
      _createNodeNotifiers();
    }
    notifyListeners();
  }

  void _resetNodeNotifiers() {
    _nodeNotifiers.values.forEach((notifier) => notifier.dispose());
    _nodeNotifiers.clear();
  }

  void _createNodeNotifiers() {
    game!.traverse((board, node) {
      final bool selected = node.rootNode;
      _nodeNotifiers[node] = AnalysisChessBoardNodeNotifier(selected);
    });
  }

  void goTo(ChessHalfMoveTreeNode node, Chess board) {
    value.currentNode = node;
    value.chessBoardController.dispose();
    value.chessBoardController = ChessBoardController.fromGame(board);
    value.chessBoardController.addListener(_onBoardChange);
    value._lastChessBoardState = board.history.last;
    _notifyAllNodeNotifiers(node);
    notifyListeners();
  }

  void _onBoardChange() {
    // Skip processing, if the board change was triggered by code
    if (_skipNextOnBoardChange == true) {
      _skipNextOnBoardChange = false;
      return;
    }

    // If the user followed a line in the analysis, let's adjust currentNode to
    // the corresponding ChessHalfMoveTreeNode
    if (value.currentNode != null && board!.history.length >= 2) {
      final secondLastBoardState = board!.history[board!.history.length - 2];
      if (identical(value._lastChessBoardState, secondLastBoardState)) {
        final children = value.currentNode!.children;
        final matchingContinuationNode = children.firstWhereOrNull(
            (child) => _movesEqual(child.move!, board!.history.last.move));
        if (matchingContinuationNode != null) {
          value.currentNode = matchingContinuationNode;
          value._lastChessBoardState = board!.history.last;
          notifyListeners();
          return;
        }
      }
    }
    // Otherwise the user has diverged from the analysis, let's set the
    // currentNode to null
    value.currentNode = null;
    value._lastChessBoardState = null;
    notifyListeners();
  }

  void goBackIfPossible() {
    if (currentNode?.rootNode ?? true) return;

    _skipNextOnBoardChange = true;

    _notifyNodeNotifier(value.currentNode!, false);
    value.currentNode = value.currentNode!.parent;
    _notifyNodeNotifier(value.currentNode!, true);
    value.chessBoardController.undoMove();
    value._lastChessBoardState =
        value.chessBoardController.game.history.lastOrNull;
    notifyListeners();
  }

  void goForward(ChessHalfMoveTreeNode child) {
    assert(identical(child.parent, currentNode));

    _skipNextOnBoardChange = true;

    _notifyNodeNotifier(value.currentNode!, false);
    value.currentNode = child;
    _notifyNodeNotifier(value.currentNode!, true);
    value.chessBoardController
        .makeMove(from: child.move!.fromAlgebraic, to: child.move!.toAlgebraic);
    value._lastChessBoardState =
        value.chessBoardController.game.history.lastOrNull;
    notifyListeners();
  }

  void _notifyNodeNotifier(ChessHalfMoveTreeNode node, bool selected) =>
      _nodeNotifiers[node]!.value = AnalysisChessBoardNodeState(selected);

  void _notifyAllNodeNotifiers(ChessHalfMoveTreeNode selectedNode) {
    _nodeNotifiers.entries.forEach((entry) {
      final ChessHalfMoveTreeNode node = entry.key;
      final AnalysisChessBoardNodeNotifier notifier = entry.value;

      notifier.value =
          AnalysisChessBoardNodeState(identical(node, selectedNode));
    });
  }

  AnalysisChessBoardNodeNotifier nodeNotifier(ChessHalfMoveTreeNode node) =>
      _nodeNotifiers[node]!;

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
