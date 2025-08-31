import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import '../services/naips_charts_service.dart';
import '../providers/charts_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/zulu_time_widget.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _bootstrapped = false;
  VoidCallback? _settingsReadyListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    final settings = context.read<SettingsProvider>();
    final charts = context.read<ChartsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only attempt load once settings have initialized with credentials.
      final haveCreds = settings.naipsEnabled && (settings.naipsUsername?.isNotEmpty == true) && (settings.naipsPassword?.isNotEmpty == true);
      if (!haveCreds) {
        debugPrint('DEBUG: ChartsScreen - delaying initial charts fetch: NAIPS creds not ready');
        // Wire a one-time listener so that as soon as settings are initialized with creds,
        // we automatically kick off verification/fetch just like pressing Retry.
        _settingsReadyListener ??= () {
          final s = context.read<SettingsProvider>();
          final ready = s.isInitialized && s.naipsEnabled && (s.naipsUsername?.isNotEmpty == true) && (s.naipsPassword?.isNotEmpty == true);
          if (ready) {
            debugPrint('DEBUG: ChartsScreen - settings ready; auto-starting charts verification');
            charts.refreshCatalogIfStale(
              ttl: const Duration(minutes: 5),
              naipsEnabled: s.naipsEnabled,
              username: s.naipsUsername,
              password: s.naipsPassword,
            );
            // Remove listener after first trigger
            if (_settingsReadyListener != null) {
              s.removeListener(_settingsReadyListener!);
              _settingsReadyListener = null;
            }
          }
        };
        settings.addListener(_settingsReadyListener!);
        return;
      }
      charts.refreshCatalogIfStale(
        ttl: const Duration(minutes: 5),
        naipsEnabled: settings.naipsEnabled,
        username: settings.naipsUsername,
        password: settings.naipsPassword,
      );
    });
  }

  @override
  void dispose() {
    final settings = context.read<SettingsProvider>();
    if (_settingsReadyListener != null) {
      settings.removeListener(_settingsReadyListener!);
      _settingsReadyListener = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<ChartsProvider>();

    final credsMissing = !(settings.naipsEnabled && (settings.naipsUsername?.isNotEmpty == true) && (settings.naipsPassword?.isNotEmpty == true));

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
            SizedBox(height: 2),
            Text(
              'Charts',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (credsMissing)
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('NAIPS credentials not set. Charts require login. Update in Settings.')),
                ],
              ),
            ),
          Expanded(
            child: (!settings.isInitialized)
                ? const _ChartsSkeleton()
                : provider.loading
                    ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(provider.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => provider.refreshCatalogIfStale(
                                  ttl: const Duration(minutes: 0),
                                  naipsEnabled: settings.naipsEnabled,
                                  username: settings.naipsUsername,
                                  password: settings.naipsPassword,
                                ),
                                child: const Text('Retry'),
                              )
                            ],
                          ),
                        ),
                      )
                    : provider.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.map, size: 48, color: Color(0xFF3B82F6)),
                                SizedBox(height: 12),
                                Text('Charts coming soon', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: provider.items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = provider.items[index];
                              final validText = item.validTillUtc != null
                                  ? 'Valid ${_fmt(item.validFromUtc)} → ${_fmt(item.validTillUtc!)}'
                                  : 'Permanent';
                              final rem = item.timeRemaining;
                              final countdown = rem == null
                                  ? ''
                                  : rem.inSeconds <= 0
                                      ? 'Expired'
                                      : '${rem.inHours.toString().padLeft(2, '0')}:${(rem.inMinutes % 60).toString().padLeft(2, '0')} remaining';
                              final timeLabel = _validityKey(item);
                              final timeColor = timeLabel == null ? null : _ValidityPalette.of(context).colorFor(timeLabel);

                              return Card(
                                child: ListTile(
                                  leading: Icon(_iconForCategory(item.category)),
                                  title: Text(item.name),
                                  subtitle: RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style.copyWith(color: Colors.black87),
                                      children: [
                                        TextSpan(text: validText),
                                        if (timeLabel != null) const TextSpan(text: ' · '),
                                        if (timeLabel != null) TextSpan(text: timeLabel, style: TextStyle(color: timeColor, fontWeight: FontWeight.w600)),
                                        if (countdown.isNotEmpty) const TextSpan(text: ' · '),
                                        if (countdown.isNotEmpty) TextSpan(text: countdown),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openViewer(context, provider.items, index),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    return '$dd $hh:00 Z';
  }

  String? _validityKey(dynamic item) {
    final validAt = item.validAtUtc as DateTime?;
    final DateTime? v = validAt ?? (item.validTillUtc != null ? null : item.validFromUtc as DateTime?);
    if (v == null) return null;
    final hh = v.hour.toString().padLeft(2, '0');
    final mm = v.minute.toString().padLeft(2, '0');
    return '${hh}${mm}Z';
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'MSL_ANALYSIS':
        return Icons.stacked_line_chart;
      case 'MSL_PROGNOSIS':
        return Icons.timeline;
      case 'SIGWX_HIGH':
        return Icons.air;
      case 'SIGWX_MID':
        return Icons.air_outlined;
      case 'GP_WINDS':
        return Icons.toys;
      case 'SATPIC':
        return Icons.satellite_alt;
      case 'SIGMET':
        return Icons.warning_amber_rounded;
      default:
        return Icons.image;
    }
  }

  void _openViewer(BuildContext context, List<dynamic> items, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ChartViewerScreen(items: items, startIndex: startIndex),
      ),
    );
  }
}

class _ChartsSkeleton extends StatelessWidget {
  const _ChartsSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black12.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Simple palette to assign a stable color per validity label (e.g., 0000Z, 0600Z)
class _ValidityPalette {
  final List<Color> _colors = const [
    Color(0xFF2563EB), // blue
    Color(0xFF059669), // green
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // purple
    Color(0xFF14B8A6), // teal
  ];
  final Map<String, Color> _cache = {};

  Color colorFor(String key) {
    return _cache.putIfAbsent(key, () => _colors[_cache.length % _colors.length]);
  }

  static _ValidityPalette of(BuildContext context) {
    // Could be lifted to InheritedWidget later; for now, a static instance is fine.
    return _globalPalette;
  }
}

final _ValidityPalette _globalPalette = _ValidityPalette();

class _ChartViewerScreen extends StatefulWidget {
  final List<dynamic> items;
  final int startIndex;
  const _ChartViewerScreen({required this.items, required this.startIndex});

  @override
  State<_ChartViewerScreen> createState() => _ChartViewerScreenState();
}

class _ChartViewerScreenState extends State<_ChartViewerScreen> with SingleTickerProviderStateMixin {
  int _quarterTurns = 0;
  final TransformationController _transformController = TransformationController();
  AnimationController? _animController;
  Animation<Matrix4>? _animation;
  Timer? _tick;
  static final Map<String, _StickyViewerState> _stickyByCode = {};
  Offset? _lastDoubleTapPos;
  late PageController _pageController;
  late int _index;
  ScrollPhysics _pagePhysics = const PageScrollPhysics();
  bool _swipeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    final pdfUrl = item.pdfUrl;
    final code = item.code?.toString() ?? '';
    // Restore sticky state once on first build
    if (_stickyByCode.containsKey(code) && _animController == null) {
      final s = _stickyByCode[code]!;
      _quarterTurns = s.quarterTurns;
      _transformController.value = s.transform;
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
            const SizedBox(height: 2),
            Text(
              item.name,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _ValidityBar(item: item),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Rotate',
            icon: const Icon(Icons.screen_rotation),
            onPressed: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
          ),
          if (pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                final uri = Uri.parse(pdfUrl.toString());
                final ok = await canLaunchUrl(uri);
                if (ok) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open PDF')),
                  );
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _pagePhysics,
            onPageChanged: (i) {
              setState(() {
                _index = i;
                _transformController.value = Matrix4.identity();
                _quarterTurns = 0;
              });
            },
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final itm = widget.items[i];
              return _ChartImageBody(
                item: itm,
                quarterTurns: _quarterTurns,
                controller: _transformController,
                onDoubleTapToggle: _handleDoubleTap,
                onDoubleTapDown: (pos) => _lastDoubleTapPos = pos,
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: _NavButton(icon: Icons.chevron_left, onTap: _prev, enabled: _index > 0),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: _NavButton(icon: Icons.chevron_right, onTap: _next, enabled: _index < widget.items.length - 1),
          ),
        ],
      ),
    );
  }

  void _handleDoubleTap() {
    // Simple toggle between identity and zoomed state (2.5x)
    final current = _transformController.value.getMaxScaleOnAxis();
    final goingIn = current < 1.5;
    final targetScale = goingIn ? 2.5 : 1.0;
    final viewportSize = context.size ?? const Size(0, 0);
    final focal = _lastDoubleTapPos ?? (viewportSize.center(Offset.zero));

    // Map the tap point to scene coordinates using inverse of current matrix
    final inv = Matrix4.inverted(_transformController.value);
    final scenePoint = Vector3(focal.dx, focal.dy, 0);
    inv.transform3(scenePoint);

    // Build a matrix that places the tapped scene point at the viewport center, at target scale
    final center = viewportSize.center(Offset.zero);
    final end = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(targetScale)
      ..translate(-scenePoint.x, -scenePoint.y);
    _animateTransform(to: end);
  }

  void _animateTransform({required Matrix4 to}) {
    _animController ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _animation = Matrix4Tween(begin: _transformController.value, end: to).animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOut));
    _animation!.addListener(() {
      _transformController.value = _animation!.value;
    });
    _animController!
      ..reset()
      ..forward();
  }

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _pageController = PageController(initialPage: _index);
    // Disable page swipe when zoomed in
    _transformController.addListener(_updateSwipePhysics);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    final current = widget.items[_index];
    final code = current.code?.toString() ?? '';
    _stickyByCode[code] = _StickyViewerState(transform: _transformController.value, quarterTurns: _quarterTurns);
    _animController?.dispose();
    _tick?.cancel();
    super.dispose();
  }

  void _updateSwipePhysics() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final shouldEnable = scale <= 1.02; // small epsilon to allow near-1x
    if (shouldEnable != _swipeEnabled) {
      setState(() {
        _swipeEnabled = shouldEnable;
        _pagePhysics = shouldEnable ? const PageScrollPhysics() : const NeverScrollableScrollPhysics();
      });
    }
  }

  void _prev() {
    if (_index > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }
  void _next() {
    if (_index < widget.items.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }
}

class _ChartImageBody extends StatefulWidget {
  final dynamic item;
  final int quarterTurns;
  final TransformationController controller;
  final VoidCallback onDoubleTapToggle;
  final ValueChanged<Offset> onDoubleTapDown;
  const _ChartImageBody({required this.item, required this.quarterTurns, required this.controller, required this.onDoubleTapToggle, required this.onDoubleTapDown});

  @override
  State<_ChartImageBody> createState() => _ChartImageBodyState();
}

class _ChartImageBodyState extends State<_ChartImageBody> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final chartsService = context.read<ChartsProvider>().chartsService;
      Uri? details = widget.item.hiResUrl ?? widget.item.loResUrl;
      if (details == null) {
        setState(() { _loading = false; _error = 'No image available for this chart'; });
        return;
      }
      // If the URL points to Details, resolve to the actual asset URL
      Uri assetUri = details;
      if (details.path.toLowerCase().contains('/chartdirectory/details/')) {
        final res = await chartsService.resolveAssetsFromDetails(details);
        if (res.imageUri != null) {
          assetUri = res.imageUri!;
        } else if (res.pdfUri != null) {
          // No image available; open PDF instead
          // ignore: use_build_context_synchronously
          final ok = await canLaunchUrl(res.pdfUri!);
          if (ok) {
            // ignore: use_build_context_synchronously
            await launchUrl(res.pdfUri!, mode: LaunchMode.externalApplication);
            setState(() { _loading = false; _bytes = null; });
            return;
          }
          setState(() { _loading = false; _error = 'No image available (PDF only)'; });
          return;
        }
      }
      final bytes = await chartsService.fetchImageBytes(
        assetUri,
        referer: details, // use Details page as referer like the browser
      );
      setState(() { _bytes = bytes; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_bytes == null) {
      return const Center(child: Text('No image available for this chart'));
    }
    return GestureDetector(
      onDoubleTap: widget.onDoubleTapToggle,
      onDoubleTapDown: (d) => widget.onDoubleTapDown(d.localPosition),
      child: InteractiveViewer(
        transformationController: widget.controller,
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: RotatedBox(
            quarterTurns: widget.quarterTurns,
            child: Image.memory(_bytes!),
          ),
        ),
      ),
    );
  }
}

class _ValidityBar extends StatelessWidget {
  final dynamic item;
  const _ValidityBar({required this.item});

  String _fmtZ(DateTime d) => '${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}Z';
  String _durShort(Duration d) {
    final neg = d.isNegative;
    final dd = d.abs();
    final h = dd.inHours;
    final m = dd.inMinutes % 60;
    if (h > 0) return '${neg ? '-' : ''}${h}h ${m}m';
    return '${neg ? '-' : ''}${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final from = item.validFromUtc as DateTime;
    final till = item.validTillUtc as DateTime?;
    final now = DateTime.now().toUtc();
    final age = now.difference(from);
    final left = till == null ? null : till.difference(now);
    final status = (left == null)
        ? 'Permanent'
        : left.isNegative
            ? 'Expired ${_durShort(left)} ago'
            : '${_durShort(left)} left';
    final primary = Colors.white70;
    final secondary = Colors.white60;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 14, color: primary),
            const SizedBox(width: 6),
            Text('Valid ${_fmtZ(from)} → ${till != null ? _fmtZ(till) : 'PERM'}', style: TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timelapse, size: 14, color: secondary),
            const SizedBox(width: 6),
            Text('${status} · age ${_durShort(age)}', style: TextStyle(fontSize: 11, color: secondary)),
          ],
        ),
      ],
    );
  }
}

class _StickyViewerState {
  final Matrix4 transform;
  final int quarterTurns;
  _StickyViewerState({required this.transform, required this.quarterTurns});
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _NavButton({required this.icon, required this.onTap, required this.enabled});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


