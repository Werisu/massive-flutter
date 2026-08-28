import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/services/workout_share_snapshot.dart';
import 'workout_share_card.dart';

Future<void> showWorkoutShareSheet(
  BuildContext context,
  WorkoutShareSnapshot snapshot, {
  String headline = 'Compartilhar treino',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    builder: (context) => WorkoutShareSheet(
      snapshot: snapshot,
      headline: headline,
    ),
  );
}

class WorkoutShareSheet extends StatefulWidget {
  const WorkoutShareSheet({
    super.key,
    required this.snapshot,
    this.headline = 'Compartilhar treino',
  });

  final WorkoutShareSnapshot snapshot;
  final String headline;

  @override
  State<WorkoutShareSheet> createState() => _WorkoutShareSheetState();
}

class _WorkoutShareSheetState extends State<WorkoutShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final png = await _capturePng();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.snapshot.fileStem}.png');
      await file.writeAsBytes(png, flush: true);

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? Rect.fromLTWH(
              0,
              0,
              MediaQuery.sizeOf(context).width,
              MediaQuery.sizeOf(context).height / 2,
            )
          : box.localToGlobal(Offset.zero) & box.size;

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
              name: '${widget.snapshot.fileStem}.png',
            ),
          ],
          text: widget.snapshot.shareCaption,
          title: widget.snapshot.workoutTitle,
          sharePositionOrigin: origin,
        ),
      );
      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível compartilhar: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<List<int>> _capturePng() async {
    final cardContext = _cardKey.currentContext;
    if (cardContext == null) {
      throw StateError('Card ainda não foi desenhado.');
    }
    final boundary = cardContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Não foi possível capturar o card.');
    }
    await WidgetsBinding.instance.endOfFrame;
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Falha ao gerar PNG.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final previewHeight = (height * 0.52).clamp(280.0, 520.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.headline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Imagem no formato de story, com cargas, PRs e progressão.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: previewHeight,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: WorkoutShareCard(snapshot: widget.snapshot),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _sharing ? 'Gerando imagem…' : 'Compartilhar',
              icon: Icons.ios_share_rounded,
              isLoading: _sharing,
              onPressed: _share,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: 'Agora não',
              onPressed: _sharing ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
