import 'package:chess/chess.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';

/// It breaks down a [GameWithVariations] to consequtive chunks.
List<LinearChessMoveSequence> breakDownToLinearChessSequences(
    GameWithVariations game) {
  final List<LinearChessMoveSequence> linearChessMoveSequencesOut = [];
  final List<LinearChessMoveSequence> linearChessMoveSequencesStack = [];

  game.traverse((board, node) {
    if (node.rootNode) return; // Root node has no visualization

    // Start a new sequence, if this is the first traversed node, or if the
    // node's parent has multiple children.
    if (linearChessMoveSequencesStack.isEmpty ||
        node.parent!.children.length > 1) {
      while (linearChessMoveSequencesStack.isNotEmpty &&
          linearChessMoveSequencesStack
                  .last.sequence.first.move.totalHalfMoveNumber >=
              node.move!.totalHalfMoveNumber) {
        linearChessMoveSequencesStack.removeLast();
      }

      var newSequence =
          LinearChessMoveSequence(depth: linearChessMoveSequencesStack.length);
      linearChessMoveSequencesOut.add(newSequence);
      linearChessMoveSequencesStack.add(newSequence);
    }
    linearChessMoveSequencesStack.last
        .addSequenceItem(LinearChessMoveSequenceItem(board.copy(), node.move!));
  });
  return linearChessMoveSequencesOut;
}

class LinearChessMoveSequence {
  final int depth;
  final List<LinearChessMoveSequenceItem> sequence = [];

  LinearChessMoveSequence({required this.depth});

  void addSequenceItem(LinearChessMoveSequenceItem item) {
    sequence.add(item);
  }

  @override
  String toString() =>
      'depth: $depth, sequence: ${sequence.isEmpty ? 'empty' : '${sequence.first.move} - ${sequence.last.move}'}';
}

class LinearChessMoveSequenceItem {
  final Chess board;
  final AnnotatedMove move;

  LinearChessMoveSequenceItem(
    this.board,
    this.move,
  );
}
