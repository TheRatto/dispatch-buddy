import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_radar_provider.dart';
import '../models/radar_site.dart';
import '../models/radar_image.dart';
import '../widgets/zulu_time_widget.dart';

class WeatherRadarScreen extends StatefulWidget {
  const WeatherRadarScreen({super.key});

  @override
  State<WeatherRadarScreen> createState() => _WeatherRadarScreenState();
}

class _WeatherRadarScreenState extends State<WeatherRadarScreen> {
  late WeatherRadarProvider _radarProvider;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _radarProvider = context.read<WeatherRadarProvider>();
      _initialized = true;
      
      // Initialize and load data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeRadar();
      });
    }
  }

  Future<void> _initializeRadar() async {
    await _radarProvider.initialize();
    if (_radarProvider.selectedSite != null) {
      // Default to loop mode on open
      await _radarProvider.loadRadarLoop();
      if (_radarProvider.currentRadarLoop.isNotEmpty) {
        _radarProvider.startAnimation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<WeatherRadarProvider>(
          builder: (context, provider, child) {
            final siteName = provider.selectedSite?.name ?? 'Weather Radar';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
                const SizedBox(height: 2),
                Text(
                  siteName,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        actions: [
          Consumer<WeatherRadarProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refresh(),
                tooltip: 'Refresh radar data',
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'change_location') {
                _showLocationSelector();
              } else if (value == 'settings') {
                _showSettings();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_location',
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Change Location'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<WeatherRadarProvider>(
        builder: (context, provider, child) {
          if (provider.availableSites.isEmpty && !provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No radar sites available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Site info and controls
              if (provider.selectedSite != null) _buildSiteInfoBar(provider),
              
              // Main radar display area
              Expanded(
                child: _buildRadarDisplay(provider),
              ),
              
              // Legend section in black area
              _buildRadarLegend(provider),
              
              // Time scale below the radar image
              if (provider.currentRadarLoop.isNotEmpty)
                _buildTimeScale(provider),
              
              // Bottom controls
              _buildBottomControls(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSiteInfoBar(WeatherRadarProvider provider) {
    final site = provider.selectedSite!;
    final image = provider.displayImage;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (image != null)
                  Text(
                    'Updated: ${image.formattedTime} (${image.formattedAge})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Range selector (only for regional radars, not national)
          if (site.id != 'NATIONAL')
            DropdownButton<String>(
              value: provider.selectedRange,
              onChanged: (range) {
                if (range != null) provider.changeRange(range);
              },
              items: site.availableRanges.map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(range),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarDisplay(WeatherRadarProvider provider) {
    final image = provider.displayImage;
    
    if (provider.isLoading && image == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading radar data...'),
          ],
        ),
      );
    }

    if (image == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No radar image available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadLatestRadarImage(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Stack(
          children: [
            // Multi-layer radar display with correct BOM transparency URLs
            if (image.layers != null)
              _buildLayeredRadarDisplay(image, provider)
            else
              _buildSingleImageRadarDisplay(image, provider),
            

          ],
        ),
      ),
    );
  }

  Widget _buildMockRadarDisplay(RadarSite site, String range) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade800,
            Colors.blue.shade700,
            Colors.blue.shade600,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Radar circles
          CustomPaint(
            size: Size.infinite,
            painter: RadarCirclesPainter(),
          ),
          
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.radar,
                  size: 48,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  '${site.name} Radar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Range: $range',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEMO MODE - BOM Data Blocked',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBottomControls(WeatherRadarProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Added bottom padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Range selection buttons
          _buildRangeSelector(provider),
          const SizedBox(height: 12),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Refresh button (small circle)
              _buildCircularButton(
                icon: provider.isLoading ? null : Icons.refresh,
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : () async {
                  if (provider.isAnimating || provider.currentRadarLoop.isNotEmpty) {
                    await provider.loadRadarLoop();
                  } else {
                    await provider.loadLatestRadarImage();
                  }
                },
                tooltip: 'Refresh',
              ),
              // Play/Pause button (small circle)
              _buildCircularButton(
                icon: provider.currentRadarLoop.isEmpty
                    ? Icons.play_circle_outline
                    : (provider.isAnimating ? Icons.pause : Icons.play_arrow),
                onPressed: provider.currentRadarLoop.isEmpty
                    ? () => provider.loadRadarLoop()
                    : provider.toggleAnimation,
                tooltip: provider.isAnimating ? 'Pause' : 'Play',
              ),
              // Location selector
              ElevatedButton.icon(
                onPressed: () => _showLocationSelector(),
                icon: const Icon(Icons.location_on),
                label: const Text('Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              // National radar button  
              ElevatedButton.icon(
                onPressed: () async {
                  // Select the national radar site
                  final nationalSite = provider.availableSites.firstWhere(
                    (site) => site.id == 'NATIONAL',
                    orElse: () => provider.availableSites.first,
                  );
                  await provider.selectSite(nationalSite);
                },
                icon: const Icon(Icons.map),
                label: const Text('National'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLocationSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return _LocationSelectorSheet(scrollController: scrollController);
        },
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Radar Settings'),
        content: const Text('Settings panel coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  /// Build legend section below the radar display
  Widget _buildRadarLegend(WeatherRadarProvider provider) {
    return Container(
      width: double.infinity,
      height: 60, // Similar to time scale height
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Image.asset(
          'assets/images/radar_legend.png',
          fit: BoxFit.contain,
          width: double.infinity, // Use full width for maximum size
          height: 44, // Use most of the container space
          errorBuilder: (context, error, stackTrace) {  
            return Container(
              height: 44,
              color: Colors.grey.shade800,
              child: const Center(
                child: Text(
                  'Legend unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build time scale with moving dot indicator
  Widget _buildTimeScale(WeatherRadarProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Start time
          Text(
            provider.currentRadarLoop.first.formattedTime,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          // Time scale with dots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(provider.currentRadarLoop.length, (index) {
                final isActive = index == provider.currentFrameIndex;
                return Container(
                  width: isActive ? 12 : 8,
                  height: isActive ? 12 : 8,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Theme.of(context).primaryColor 
                        : Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          // End time
          Text(
            provider.currentRadarLoop.last.formattedTime,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build range selector buttons
  Widget _buildRangeSelector(WeatherRadarProvider provider) {
    final selectedSite = provider.selectedSite;
    if (selectedSite == null) return const SizedBox.shrink();
    
    // Don't show range selector for National radar - leave space blank
    if (selectedSite.id == 'NATIONAL') {
      return const SizedBox(height: 44); // Same height as range buttons
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: selectedSite.availableRanges.map((range) {
        final isSelected = provider.selectedRange == range;
        return GestureDetector(
          onTap: () => provider.changeRange(range),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build circular control button
  Widget _buildCircularButton({
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  /// Build layered radar display using BOM's multi-layer system
  Widget _buildLayeredRadarDisplay(RadarImage image, WeatherRadarProvider provider) {
    final layers = image.layers!;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Background map (coastlines, borders)
        _buildRadarLayer(
          layers.backgroundUrl,
          'Background Map',
          fallback: Container(color: Colors.blue.shade900),
        ),
        
        // Layer 2: Topography (terrain features)
        _buildRadarLayer(
          layers.topographyUrl,
          'Topography',
        ),
        
        // Layer 3: Range circles (distance references)
        _buildRadarLayer(
          layers.rangeUrl,
          'Range Circles',
        ),
        
        // Layer 4: Location labels (city names)
        _buildRadarLayer(
          layers.locationsUrl,
          'Location Labels',
        ),
        
        // Layer 5: Radar data (actual weather - this animates)
        _buildRadarLayer(
          layers.radarDataUrl,
          'Radar Data',
          showLoading: true,
          fallback: _buildMockRadarDisplay(provider.selectedSite!, provider.selectedRange),
        ),
        

      ],
    );
  }

  /// Build single image radar display with enhanced overlays
  Widget _buildSingleImageRadarDisplay(RadarImage image, WeatherRadarProvider provider) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main radar image from BOM
        Image.network(
          image.url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading radar image...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildMockRadarDisplay(provider.selectedSite!, provider.selectedRange);
          },
        ),
        
        // Optional: Add our own range circles overlay
        CustomPaint(
          size: Size.infinite,
          painter: RadarRangeOverlayPainter(provider.selectedRange),
        ),
      ],
    );
  }

  /// Build individual radar layer with error handling
  Widget _buildRadarLayer(
    String imageUrl, 
    String layerName, {
    Widget? fallback,
    bool showLoading = false,
    double? width,
    double? height,
  }) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      loadingBuilder: showLoading ? (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading $layerName...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      } : null,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('DEBUG: Failed to load $layerName layer: $imageUrl - Error: $error');
        // Return fallback or transparent container
        return fallback ?? Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          color: Colors.transparent,
        );
      },
    );
  }
}

/// Custom painter to draw radar range circles
class RadarCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width < size.height ? size.width / 2 : size.height / 2;

    // Draw concentric circles representing radar ranges
    for (int i = 1; i <= 4; i++) {
      final radius = (maxRadius * i) / 4;
      canvas.drawCircle(center, radius, paint);
    }

    // Draw crosshairs
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom painter for radar range overlay on real BOM images
class RadarRangeOverlayPainter extends CustomPainter {
  final String range;
  
  RadarRangeOverlayPainter(this.range);

  @override
  void paint(Canvas canvas, Size size) {
    // BOM images already include range circles, so keep overlay minimal
    // Only add subtle range indicators if needed
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Most BOM radar images already have proper range circles
    // This painter is available for future enhancements
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _LocationSelectorSheet extends StatelessWidget {
  final ScrollController scrollController;

  const _LocationSelectorSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherRadarProvider>(
      builder: (context, provider, child) {
        final sitesByState = provider.sitesByState;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              const Text(
                'Select Radar Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
                            // State tabs and locations
              Expanded(
                child: DefaultTabController(
                  length: sitesByState.keys.length + 1, // +1 for Favorites tab
                  child: Column(
                    children: [
                      ClipRect(
                        child: TabBar(
                          isScrollable: false,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          labelPadding: EdgeInsets.zero,
                          indicatorPadding: EdgeInsets.zero,
                          labelStyle: const TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                          labelColor: Colors.black87,
                          unselectedLabelColor: Colors.black87,
                          indicatorColor: const Color(0xFF1E3A8A),
                          indicatorWeight: 3,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
                          splashFactory: NoSplash.splashFactory,
                          tabs: [
                            // Favorites tab first
                            const Tab(
                              icon: Icon(Icons.star, size: 20),
                              height: 40,
                            ),
                            // Then state tabs
                            ...sitesByState.keys.map((state) => Tab(
                              text: state,
                              height: 40,
                            )).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Favorites tab content
                            _buildFavoritesTab(provider, scrollController),
                            // State tabs content
                            ...sitesByState.entries.map((entry) {
                              return ListView.builder(
                                controller: scrollController,
                                itemCount: entry.value.length,
                                itemBuilder: (context, index) {
                                  final site = entry.value[index];
                                  final isSelected = provider.selectedSite?.id == site.id;
                                  final isFavorite = provider.isFavorite(site.id);
                                  
                                  return ListTile(
                                    leading: Icon(
                                      Icons.radar,
                                      color: isSelected 
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      site.name,
                                      style: TextStyle(
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(site.location),
                                    trailing: SizedBox(
                                      width: 96, // Fixed width to maintain alignment
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorite ? Icons.star : Icons.star_border,
                                              color: isFavorite ? Colors.amber : Colors.grey,
                                            ),
                                            onPressed: () => provider.toggleFavorite(site.id),
                                          ),
                                          SizedBox(
                                            width: 24, // Fixed space for check mark
                                            child: isSelected ? Icon(
                                              Icons.check_circle,
                                              color: Theme.of(context).primaryColor,
                                            ) : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      provider.selectSite(site);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build favorites tab content
  Widget _buildFavoritesTab(WeatherRadarProvider provider, ScrollController scrollController) {
    final favoriteSites = provider.favoriteSites;
    
    if (favoriteSites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the star icon next to any radar site\nto add it to your favorites',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: scrollController,
      itemCount: favoriteSites.length,
      itemBuilder: (context, index) {
        final site = favoriteSites[index];
        final isSelected = provider.selectedSite?.id == site.id;
        
        return ListTile(
          leading: Icon(
            Icons.radar,
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          title: Text(
            site.name,
            style: TextStyle(
              fontWeight: isSelected 
                  ? FontWeight.bold 
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text('${site.location} (${site.state})'),
          trailing: SizedBox(
            width: 96, // Fixed width to maintain alignment
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onPressed: () => provider.toggleFavorite(site.id),
                ),
                SizedBox(
                  width: 24, // Fixed space for check mark
                  child: isSelected ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  ) : null,
                ),
              ],
            ),
          ),
          onTap: () {
            provider.selectSite(site);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
