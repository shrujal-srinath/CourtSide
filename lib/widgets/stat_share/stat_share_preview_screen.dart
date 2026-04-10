// lib/widgets/stat_share/stat_share_preview_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import 'stat_share_card.dart';

class StatSharePreviewScreen extends StatefulWidget {
  const StatSharePreviewScreen({super.key, this.extra});
  final Object? extra;

  @override
  State<StatSharePreviewScreen> createState() => _StatSharePreviewScreenState();
}

class _StatSharePreviewScreenState extends State<StatSharePreviewScreen> {
  final _repaintKey = GlobalKey();
  bool _isExporting = false;

  // Extract stat data from the extra parameter (PlayerGameStat)
  PlayerGameStat? get _stat =>
      widget.extra is PlayerGameStat ? widget.extra as PlayerGameStat : null;

  String get _playerName => 'Player'; // real name comes from auth provider
  String get _sport => _stat?.sport ?? 'basketball';
  String get _gameDate {
    final now = DateTime.now();
    return '${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  String get _venueName => 'Arena Game';

  Map<String, String> get _stats {
    if (_stat == null) return {};
    return _stat!.stats
        .map((k, v) => MapEntry(k, v.toString()));
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Future<void> _exportAndShare() async {
    setState(() => _isExporting = true);
    // Let the static (non-animated) frame render
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'courtside_stats.png',
            mimeType: 'image/png',
          )
        ],
        text: 'My game stats via Courtside 🏀',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Your Stat Card',
          style: AppTextStyles.headingM(AppColors.textPrimaryDark),
        ),
        actions: [
          if (!_isExporting)
            TextButton(
              onPressed: _exportAndShare,
              child: Text(
                'Share',
                style: AppTextStyles.headingS(AppColors.red),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Card preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: StatShareCard(
                    playerName: _playerName,
                    sport: _sport,
                    gameDate: _gameDate,
                    venueName: _venueName,
                    stats: _stats,
                    isExporting: _isExporting,
                  ),
                ),
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: AppTextStyles.headingS(AppColors.textPrimaryDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportAndShare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded,
                            color: Colors.white, size: 18),
                    label: Text(
                      _isExporting ? 'Preparing...' : 'Share to Story',
                      style: AppTextStyles.headingS(AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
