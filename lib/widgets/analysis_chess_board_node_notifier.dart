import 'package:flutter/foundation.dart';

class AnalysisChessBoardNodeState {
  final bool selected;

  AnalysisChessBoardNodeState(this.selected);

  @override
  int get hashCode => Object.hashAll([selected]);

  @override
  bool operator ==(Object other) =>
      other is AnalysisChessBoardNodeState && selected == other.selected;
}

class AnalysisChessBoardNodeNotifier
    extends ValueNotifier<AnalysisChessBoardNodeState> {
  AnalysisChessBoardNodeNotifier(bool selected)
      : super(AnalysisChessBoardNodeState(selected));
}
