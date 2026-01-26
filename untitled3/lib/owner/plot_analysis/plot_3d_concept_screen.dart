import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../common/three_d/building_model.dart';
import '../../common/three_d/three_d_html_generator.dart';
import 'market_price_service.dart';

/// Enhanced 3D Concept Visualization Screen
/// 
/// This screen displays an interactive 3D building visualization using:
/// - Modular Three.js architecture (separated geometry, rendering, camera, interaction)
/// - Realistic lighting and materials
/// - Smooth gesture controls (rotate, zoom, pan)
/// - Data-driven geometry (responds to plot dimensions and floor count)
/// - AI-ready parameters (facade style, roof type, color palette)
/// - Market-based pricing information (per sq ft, total estimated cost)
/// 
/// Architecture:
/// - BuildingModel: Defines parametric geometry
/// - BuildingRenderer: Handles lighting, materials, scene setup
/// - CameraController: Manages camera and orbit controls
/// - InteractionController: Handles user interactions and animation loop
/// - ThreeDHtmlGenerator: Assembles everything into HTML
/// - MarketPriceService: Provides market pricing by location
class Plot3DConceptScreen extends StatefulWidget {
  final double plotLength;
  final double plotWidth;
  final int floors;
  final String? city; // City/pincode for market pricing
  final BuildingModel? buildingModel; // Optional AI-generated model

  const Plot3DConceptScreen({
    super.key,
    required this.plotLength,
    required this.plotWidth,
    required this.floors,
    this.city,
    this.buildingModel, // Can be provided by AI service
  });

  @override
  State<Plot3DConceptScreen> createState() => _Plot3DConceptScreenState();
}

class _Plot3DConceptScreenState extends State<Plot3DConceptScreen> {
  late final WebViewController _controller;
  late final BuildingModel _buildingModel;
  bool _isLoading = true;
  double _pricePerSqFt = 5000.0;
  double _totalEstimatedPrice = 0.0;
  String _marketLocation = 'India';

  @override
  void initState() {
    super.initState();

    // Use AI-generated model if provided, otherwise create default
    _buildingModel = widget.buildingModel ?? BuildingModel(
      plotWidth: widget.plotWidth,
      plotLength: widget.plotLength,
      floors: widget.floors,
      floorHeight: 3.0, // Standard 3m per floor
      buildingFootprintRatio: 0.80, // 80% of plot
      setbackRatio: 0.10, // 10% setback
      // Default parameters
      facadeStyle: 'modern',
      roofType: 'flat',
      colorPalette: [0xfafafa, 0xf5f5f5, 0xf0f0f0], // White/gray tones
    );

    // Load market pricing if city is provided
    if (widget.city != null && widget.city!.isNotEmpty) {
      _loadMarketPricing(widget.city!);
    }

    // Generate HTML using modular architecture
    final String htmlContent = ThreeDHtmlGenerator.generateHtml(_buildingModel);

    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8F1F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(htmlContent);
    
    debugPrint('Building Model: $_buildingModel');
  }

  Future<void> _loadMarketPricing(String cityOrPincode) async {
    try {
      final pricePerSqFt = await MarketPriceService.getPricePerSqFt(cityOrPincode);
      
      // Calculate building area in square feet
      final buildingAreaSqMeter = _buildingModel.buildingLength * _buildingModel.buildingWidth;
      final buildingAreaSqFt = MarketPriceService.sqMeterToSqFt(buildingAreaSqMeter);
      
      // Calculate total estimated price
      final totalPrice = MarketPriceService.calculateTotalPrice(buildingAreaSqFt, pricePerSqFt);
      
      if (mounted) {
        setState(() {
          _pricePerSqFt = pricePerSqFt;
          _totalEstimatedPrice = totalPrice;
          _marketLocation = cityOrPincode;
        });
      }
      
      debugPrint('Market Price Loaded: ₹$pricePerSqFt/sq ft for $cityOrPincode');
    } catch (e) {
      debugPrint('Error loading market pricing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F5),
      appBar: AppBar(
        title: const Text(
          "3D Concept View (Beta)",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          // Info button to explain controls
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Controls',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('3D Controls'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🖱️ Drag to rotate'),
                      SizedBox(height: 8),
                      Text('🔍 Scroll/Pinch to zoom'),
                      SizedBox(height: 8),
                      Text('⌨️ Right-click to pan'),
                      SizedBox(height: 8),
                      Text('👆 Double-tap to reset view'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF136DEC)),
                  SizedBox(height: 16),
                  Text(
                    'Rendering 3D Concept...',
                    style: TextStyle(
                      color: Color(0xFF5C5C5C),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Safety Label Overlay
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Concept visualization only. Not for construction.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // Plot Info Overlay (Left side)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF136DEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.architecture,
                          size: 18,
                          color: Color(0xFF136DEC),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Building Info',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Plot',
                    value: '${widget.plotLength}m × ${widget.plotWidth}m',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Building',
                    value: '${_buildingModel.buildingLength.toStringAsFixed(1)}m × ${_buildingModel.buildingWidth.toStringAsFixed(1)}m',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Floors',
                    value: '${widget.floors} (${_buildingModel.totalHeight}m)',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Style',
                    value: _buildingModel.facadeStyle.toUpperCase(),
                  ),
                ],
              ),
            ),
          ),

          // Market Pricing Info Overlay (Right side)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Market Price (2026)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Location',
                    value: _marketLocation,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Per Sq Ft',
                    value: '₹${_pricePerSqFt.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Built-up Area',
                    value: '${(_buildingModel.buildingLength * _buildingModel.buildingWidth).toStringAsFixed(0)} m²',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Built-up Area',
                    value: '${MarketPriceService.sqMeterToSqFt(_buildingModel.buildingLength * _buildingModel.buildingWidth).toStringAsFixed(0)} sq ft',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MarketPriceService.formatPrice(_totalEstimatedPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(₹${_totalEstimatedPrice.toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Estimate only. Consult local agents.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
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
  }
}

/// Info row widget for building details
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
