import 'package:chess_collections/widgets/analysis_chess_board_controller.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:logging/logging.dart';
import 'package:chess/chess.dart' as ch;

import '../util/constants.dart';
import 'import_pgn_dialog.dart';

final _logger = Logger('home_page');

class AnalysisChessBoardPage extends StatefulWidget {
  static final _globalKey = GlobalKey();

  AnalysisChessBoardPage() : super(key: _globalKey);

  @override
  State<AnalysisChessBoardPage> createState() => _AnalysisChessBoardPageState();
}

class _AnalysisChessBoardPageState extends State<AnalysisChessBoardPage> {
  ChessHalfMoveTree? game;
  late AnalysisChessBoardController controller;
  bool _importPgnDialogOpen = false;
  late FocusNode _focusNode;
  PlayerColor _boardOrientation = PlayerColor.white;

  @override
  void initState() {
    super.initState();

    controller = AnalysisChessBoardController();
    _focusNode = FocusNode(debugLabel: 'AnalysisChessBoardPage');
    _focusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (game == null && mounted) _importPgn();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChessCollectionsAppBar(
        onPgnImportPressed: _importPgn,
        onFlipBoardPressed: _flipBoard,
      ),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: ValueListenableBuilder<AnalysisChessBoardState>(
          valueListenable: controller,
          builder: (context, state, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 12,
                child: ChessBoard(
                  controller: controller.chessBoardController,
                  boardColor: BoardColor.brown,
                  boardOrientation: _boardOrientation,
                  arrows: controller.currentNode?.move?.visualAnnotations
                          .whereType<Arrow>()
                          .map(
                            (e) => BoardArrow(
                              from: Chess.algebraic(e.from),
                              to: Chess.algebraic(e.to),
                              color: _visualAnnotationColorToColor(e.color),
                            ),
                          )
                          .toList() ??
                      [],
                ),
              ),
              if (controller.game != null)
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ChessGameMetadata(tags: controller.game!.tags),
                            ChessMoveHistory(
                              analysisChessBoardController: controller,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _visualAnnotationColorToColor(VisualAnnotationColor color) {
    final map = <VisualAnnotationColor, Color>{
      VisualAnnotationColor.blue: Colors.blue.shade400,
      VisualAnnotationColor.green: Colors.green.shade400,
      VisualAnnotationColor.red: Colors.red.shade400,
      VisualAnnotationColor.yellow: Colors.yellow.shade400,
    };
    return (map[color] ?? map[VisualAnnotationColor.blue]!).withOpacity(0.5);
  }

  void _importPgn() async {
    if (_importPgnDialogOpen) {
      _logger.info('ImportPgnDialog is already open, ignoring request');
      return;
    }
    setState(() => _importPgnDialogOpen = true);
    final importedGame = await _showImportDialogPgn();
    setState(() => _importPgnDialogOpen = false);
    _logger.info(
        'The imported games are (choosing the first game):\n$importedGame');
    controller.loadGame(importedGame?.firstOrNull);
  }

  Future<List<ChessHalfMoveTree>?> _showImportDialogPgn() {
    return showDialog<List<ChessHalfMoveTree>>(
      context: context,
      builder: (BuildContext context) => const ImportPgnDialog(),
    );
  }

  void _flipBoard() {
    setState(() {
      _boardOrientation = _boardOrientation == PlayerColor.white
          ? PlayerColor.black
          : PlayerColor.white;
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _logger.info('Left key pressed');
        controller.goBackIfPossible();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _logger.info('Right key pressed');
        if (controller.currentNode != null &&
            controller.currentNode!.children.isNotEmpty) {
          controller.goForward(controller.currentNode!.children.first);
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // TODO previous variation
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // TODO next variation
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}

class ChessCollectionsAppBar extends AppBar {
  ChessCollectionsAppBar({
    required VoidCallback onPgnImportPressed,
    required VoidCallback onFlipBoardPressed,
    Key? key,
  }) : super(
          title: const Text('Chess Collections'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.file_open),
              onPressed: onPgnImportPressed,
              tooltip: 'Import PGN',
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              onPressed: onFlipBoardPressed,
              tooltip: 'Flip board',
            ),
          ],
          key: key,
        );
}

class ChessGameMetadata extends StatelessWidget {
  static const _playerNamesStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const _additionalTagsStyle = TextStyle(fontSize: 16);
  final ChessGameTags tags;
  const ChessGameMetadata({required this.tags, Key? key}) : super(key: key);

  String _capitalizeFirstLetter(String string) {
    if (string.isEmpty) return '';
    return string.substring(0, 1).toUpperCase() + string.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    String formatPlayers(List<String> players, String? elo) {
      final playerNames = players.isEmpty ? 'unknown' : players.join(', ');
      // \u{00A0} means non-breaking space
      return '$playerNames${elo != null ? '\u{00A0}($elo)' : ''}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${formatPlayers(tags.white, tags.whiteElo)} vs ${formatPlayers(tags.black, tags.blackElo)}',
            style: _playerNamesStyle,
          ),
          Text(
            _capitalizeFirstLetter([
              if (tags.event != null) 'event: ${tags.event}',
              if (tags.round != null) 'round: ${tags.round}',
              if (tags.site != null) 'site: ${tags.site}',
              if (tags.date != null)
                'date: ${Constants.dateFormat.format(tags.date!)}',
            ].join(', ')),
            style: _additionalTagsStyle,
          )
        ],
      ),
    );
  }
}

class ChessMoveHistory extends StatelessWidget {
  final AnalysisChessBoardController analysisChessBoardController;

  const ChessMoveHistory({
    required this.analysisChessBoardController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return analysisChessBoardController.game == null
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _generateRows(),
          );
  }

  List<Widget> _generateRows() {
    final linearMoveSequenceTree = LinearMoveSequenceTree.fromGame(
        analysisChessBoardController.game!,
        captureBoards: true);

    final linearMoveSequences = <LinearMoveSequenceTreeNode>[];
    linearMoveSequenceTree.traverse((node) => linearMoveSequences.add(node));

    return linearMoveSequences
        .map((item) => LinearChessMoveSequenceWidget(
              analysisChessBoardController: analysisChessBoardController,
              linearChessMoveSequence: item,
            ))
        .toList();
  }
}

class LinearChessMoveSequenceWidget extends StatelessWidget {
  final AnalysisChessBoardController analysisChessBoardController;
  final LinearMoveSequenceTreeNode linearChessMoveSequence;

  const LinearChessMoveSequenceWidget({
    required this.analysisChessBoardController,
    required this.linearChessMoveSequence,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12 * linearChessMoveSequence.depth.toDouble(),
        bottom: 8,
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        children: linearChessMoveSequence.sequence.map((item) {
          return ChessMove(
            analysisChessBoardController: analysisChessBoardController,
            node: item.node,
            board: item.board!,
          );
        }).toList(),
      ),
    );
  }
}

class ChessMove extends StatefulWidget {
  final AnalysisChessBoardController analysisChessBoardController;
  final ChessHalfMoveTreeNode node;
  final Chess board;

  ChessMove({
    required this.analysisChessBoardController,
    required this.node,
    required this.board,
    Key? key,
  })  : assert(!node.rootNode),
        super(key: key);

  @override
  State<ChessMove> createState() => _ChessMoveState();
}

class _ChessMoveState extends State<ChessMove> {
  static const _mainLineMoveNumberTextStyle =
      TextStyle(fontWeight: FontWeight.bold);
  static const _mainLineMoveTextStyle =
      TextStyle(decoration: TextDecoration.underline);
  static const _sideLineMoveNumberTextStyle =
      TextStyle(fontWeight: FontWeight.bold);
  static const _sideLineMoveTextStyle = TextStyle();
  static const _commentTextStyle = TextStyle(fontStyle: FontStyle.italic);

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: '_ChessMoveState ${widget.node.move}');
    widget.analysisChessBoardController.addListener(_onBoardChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.analysisChessBoardController.removeListener(_onBoardChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChessMove oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.analysisChessBoardController.removeListener(_onBoardChanged);
    widget.analysisChessBoardController.addListener(_onBoardChanged);
  }

  void _onBoardChanged() {
    final selected =
        widget.analysisChessBoardController.currentNode == widget.node;
    if (selected) {
      _focusNode.requestFocus();
    }
  }

  void _onMoveSelected() {
    widget.analysisChessBoardController.goTo(widget.node, widget.board);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        focusNode: _focusNode,
        onTap: _onMoveSelected,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show the move number indicator only for white moves and for
              // first moves after a decision point
              if (widget.node.move!.color == ch.Color.WHITE ||
                  widget.node.parent!.children.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    widget.node.move!.moveNumberIndicator,
                    style: widget.node.variationDepth == 0
                        ? _mainLineMoveNumberTextStyle
                        : _sideLineMoveNumberTextStyle,
                  ),
                ),
              Text(widget.node.move!.san,
                  style: widget.node.variationDepth == 0
                      ? _mainLineMoveTextStyle
                      : _sideLineMoveTextStyle),
              if (widget.node.move!.comment != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(widget.node.move!.comment!,
                      style: _commentTextStyle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
