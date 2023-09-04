import 'package:flutter/foundation.dart';

class AnalysisChessBoardNodeState {
  final bool selected;
  final bool pastMove;

  AnalysisChessBoardNodeState({
    required this.selected,
    required this.pastMove,
  }) : assert(!(selected && pastMove));

  @override
  int get hashCode => Object.hashAll([selected, pastMove]);

  @override
  bool operator ==(Object other) =>
      other is AnalysisChessBoardNodeState &&
      selected == other.selected &&
      pastMove == other.pastMove;
}

class AnalysisChessBoardNodeNotifier
    extends ValueNotifier<AnalysisChessBoardNodeState> {
  AnalysisChessBoardNodeNotifier({
    required bool selected,
    required bool pastMove,
  }) : super(AnalysisChessBoardNodeState(
          selected: selected,
          pastMove: pastMove,
        ));
}
