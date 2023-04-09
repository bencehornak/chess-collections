import 'dart:convert';
import 'dart:math';

import 'package:chess_collections/widgets/analysis_chess_board_controller.dart';
import 'package:chess_pgn_parser/chess_pgn_parser.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:logging/logging.dart';
import 'package:chess/chess.dart' as ch;

import '../util/constants.dart';

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
  PlayerColor _boardOrientation = PlayerColor.white;

  @override
  void initState() {
    super.initState();

    controller = AnalysisChessBoardController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (game == null && mounted) _importPgn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChessCollectionsAppBar(
        onPgnImportPressed: _importPgn,
        onFlipBoardPressed: _flipBoard,
      ),
      body: AppContent(
        controller: controller,
        boardOrientation: _boardOrientation,
        onPgnImportPressed: _importPgn,
      ),
    );
  }

  void _importPgn() async {
    if (_importPgnDialogOpen) {
      _logger.info('ImportPgnDialog is already open, ignoring request');
      return;
    }
    setState(() => _importPgnDialogOpen = true);
    List<ChessHalfMoveTree>? importedGames;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,
        allowedExtensions: ['pgn'],
      );

      if (result != null) {
        String pgnString = utf8.decode(result.files.single.bytes!.toList());
        importedGames = PgnReader.fromString(pgnString).parse();
      }
    } catch (error, stackTrace) {
      _logger.warning('Error while parsing PGN', error, stackTrace);
      _showError(error);
    }

    setState(() => _importPgnDialogOpen = false);
    _logger.info(
        'The imported games are (choosing the first game):\n$importedGames');
    controller.loadGame(importedGames?.firstOrNull);
  }

  void _showError(dynamic error) {
    if (!mounted) return;

    var themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final snackBar = SnackBar(
      content:
          Text(error.toString(), style: TextStyle(color: colorScheme.onError)),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: _importPgn,
        textColor: colorScheme.onError,
      ),
      backgroundColor: colorScheme.error,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _flipBoard() {
    setState(() {
      _boardOrientation = _boardOrientation == PlayerColor.white
          ? PlayerColor.black
          : PlayerColor.white;
    });
  }
}

class AppContent extends StatefulWidget {
  final AnalysisChessBoardController controller;
  final PlayerColor boardOrientation;
  final VoidCallback onPgnImportPressed;

  const AppContent({
    required this.controller,
    required this.boardOrientation,
    required this.onPgnImportPressed,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode(debugLabel: 'AnalysisChessBoardPage');
    _focusNode.requestFocus();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: LayoutBuilder(builder: (context, constraint) {
        if (constraint.maxWidth / constraint.maxHeight >= 1.0) {
          return _buildLargeScreen(context, constraint);
        } else {
          return _buildSmallScreen(context, constraint);
        }
      }),
    );
  }

  Widget _buildLargeScreen(BuildContext context, BoxConstraints constraint) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: min(constraint.maxHeight - 80, .6 * constraint.maxWidth),
            child: MaterialChessBoardWithButtons(
              controller: widget.controller,
              boardOrientation: widget.boardOrientation,
              chessBoardFlex: 0,
            ),
          ),
          SidePanel(
            controller: widget.controller,
            onPgnImportPressed: widget.onPgnImportPressed,
          ),
        ],
      );

  Widget _buildSmallScreen(BuildContext context, BoxConstraints constraint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: min(constraint.maxWidth, .65 * constraint.maxHeight),
            child: MaterialChessBoardWithButtons(
              controller: widget.controller,
              boardOrientation: widget.boardOrientation,
              chessBoardFlex: 1,
            ),
          ),
          SidePanel(
            controller: widget.controller,
            onPgnImportPressed: widget.onPgnImportPressed,
          ),
        ],
      );

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _logger.info('Left key pressed');
        widget.controller.goBackIfPossible();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _logger.info('Right key pressed');
        if (widget.controller.currentNode != null &&
            widget.controller.currentNode!.children.isNotEmpty) {
          widget.controller
              .goForward(widget.controller.currentNode!.children.first);
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

class MaterialChessBoardWithButtons extends StatelessWidget {
  final AnalysisChessBoardController controller;
  final PlayerColor boardOrientation;
  final int chessBoardFlex;

  const MaterialChessBoardWithButtons({
    super.key,
    required this.controller,
    required this.boardOrientation,
    required this.chessBoardFlex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: chessBoardFlex,
            child: MaterialChessBoard(
              controller: controller,
              boardOrientation: boardOrientation,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          MaterialControllerButtons(
            controller: controller,
          ),
        ],
      ),
    );
  }
}

class MaterialChessBoard extends StatelessWidget {
  final AnalysisChessBoardController controller;
  final PlayerColor boardOrientation;

  const MaterialChessBoard({
    super.key,
    required this.controller,
    required this.boardOrientation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, child) => ChessBoard(
          controller: controller.chessBoardController,
          boardColor: BoardColor.brown,
          boardOrientation: boardOrientation,
          lastMoveHighlightColor: Colors.yellow.withOpacity(.3),
          arrows: value.currentNode?.move?.visualAnnotations
                  .whereType<Arrow>()
                  .map(
                    (e) => BoardArrow(
                      from: Chess.algebraic(e.from),
                      to: Chess.algebraic(e.to),
                      color:
                          _visualAnnotationColorToColor(e.color, opacity: .5),
                    ),
                  )
                  .toList() ??
              [],
          highlightedSquares: value.currentNode?.move?.visualAnnotations
                  .whereType<HighlightedSquare>()
                  .map(
                    (e) => BoardHighlightedSquare(
                      Chess.algebraic(e.square),
                      color:
                          _visualAnnotationColorToColor(e.color, opacity: .5),
                    ),
                  )
                  .toList() ??
              [],
        ),
      ),
    );
  }

  static Color _visualAnnotationColorToColor(VisualAnnotationColor color,
      {required double opacity}) {
    final map = <VisualAnnotationColor, Color>{
      VisualAnnotationColor.blue: Colors.blue.shade400,
      VisualAnnotationColor.green: Colors.green.shade400,
      VisualAnnotationColor.red: Colors.red.shade400,
      VisualAnnotationColor.yellow: Colors.yellow.shade400,
    };
    return (map[color] ?? map[VisualAnnotationColor.blue]!)
        .withOpacity(opacity);
  }
}

class MaterialControllerButtons extends StatelessWidget {
  final AnalysisChessBoardController controller;

  const MaterialControllerButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        MaterialControllerButton(
          icon: Icons.arrow_left,
          onPressed: _goBackIfPossible,
        ),
        MaterialControllerButton(
          icon: Icons.arrow_right,
          onPressed: _goForward,
        ),
      ],
    );
  }

  void _goBackIfPossible() {
    controller.goBackIfPossible();
  }

  void _goForward() {
    if (controller.currentNode == null) return;
    controller.goForward(controller.currentNode!.children.first);
  }
}

class MaterialControllerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const MaterialControllerButton(
      {super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Ink(
      decoration: ShapeDecoration(
        color: colors.primary,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: colors.inversePrimary,
        onPressed: onPressed,
      ),
    );
  }
}

class SidePanel extends StatelessWidget {
  final AnalysisChessBoardController controller;
  final VoidCallback onPgnImportPressed;

  const SidePanel({
    super.key,
    required this.controller,
    required this.onPgnImportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) => Expanded(
        child: value.game == null
            ? NoGameLoadedPanel(
                onPgnImportPressed: onPgnImportPressed,
              )
            : GameLoadedPanel(
                controller: controller,
              ),
      ),
    );
  }
}

class NoGameLoadedPanel extends StatelessWidget {
  final VoidCallback onPgnImportPressed;

  const NoGameLoadedPanel({
    required this.onPgnImportPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: FilledButton.icon(
        onPressed: onPgnImportPressed,
        icon: const Icon(Icons.file_open),
        label: const Text('Open a PGN file'),
      ),
    );
  }
}

class GameLoadedPanel extends StatelessWidget {
  final AnalysisChessBoardController controller;

  const GameLoadedPanel({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChessGameMetadata(
                controller: controller,
              ),
              ChessMoveHistory(
                analysisChessBoardController: controller,
              ),
            ],
          ),
        ),
      ),
    );
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
              tooltip: 'Open a PGN file',
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
  final AnalysisChessBoardController controller;
  const ChessGameMetadata({required this.controller, Key? key})
      : super(key: key);

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

    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final tags = value.game!.tags;
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
      },
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
          child: Text.rich(
            TextSpan(
              children: [
                // Show the move number indicator only for white moves and for
                // first moves after a decision point
                if (widget.node.move!.color == ch.Color.WHITE ||
                    widget.node.parent!.children.length > 1)
                  TextSpan(
                    text: widget.node.move!.moveNumberIndicator,
                    style: widget.node.variationDepth == 0
                        ? _mainLineMoveNumberTextStyle
                        : _sideLineMoveNumberTextStyle,
                  ),
                TextSpan(
                    text: widget.node.move!.san,
                    style: widget.node.variationDepth == 0
                        ? _mainLineMoveTextStyle
                        : _sideLineMoveTextStyle),
                if (widget.node.move!.comment != null)
                  TextSpan(
                      text: widget.node.move!.comment!,
                      style: _commentTextStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
