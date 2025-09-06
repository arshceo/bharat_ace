import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bharat_ace/core/services/career_json_service.dart';
import 'sparkle_particle_painter.dart';
import 'career_detail_screen.dart';

class CareerPathVisualizationScreen extends StatefulWidget {
  const CareerPathVisualizationScreen({super.key});

  @override
  State<CareerPathVisualizationScreen> createState() =>
      _CareerPathVisualizationScreenState();
}

class _CareerPathVisualizationScreenState
    extends State<CareerPathVisualizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Map<String, dynamic> _careersData = {};
  Map<String, dynamic> _filteredCareers = {};
  List<String> _categories = [];
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // For the particle effect
  final List<SparkleParticle> _sparkles = [];
  final int _numSparkles = 100;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initializeSparkles();
    _loadCareerData();
  }

  void _initializeSparkles() {
    final random = math.Random();
    for (int i = 0; i < _numSparkles; i++) {
      _sparkles.add(
        SparkleParticle(
          position: Offset(
            random.nextDouble() * 500,
            random.nextDouble() * 800,
          ),
          size: random.nextDouble() * 3 + 1,
          velocity: Offset(
            (random.nextDouble() - 0.5) * 0.5,
            (random.nextDouble() - 0.5) * 0.5,
          ),
          color: _getRandomSparkleColor(random),
          lifespan: random.nextDouble() * 3 + 1,
        ),
      );
    }
  }

  Color _getRandomSparkleColor(math.Random random) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFF00BFFF), // Deep Sky Blue
      const Color(0xFFFFA500), // Orange
      const Color(0xFF7B68EE), // Medium Slate Blue
      const Color(0xFFFF1493), // Deep Pink
    ];
    return colors[random.nextInt(colors.length)]
        .withOpacity(0.5 + random.nextDouble() * 0.5);
  }

  Future<void> _loadCareerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await CareerJsonService.loadCareersData();

      setState(() {
        _careersData = data;
        _filteredCareers = data;
        _categories = _getCareerCategories(data);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading career data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load career data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
        _careersData = {};
        _filteredCareers = {};
        _categories = [];
      });
    }
  }

  List<String> _getCareerCategories(Map<String, dynamic> careers) {
    final categories = <String>{};

    careers.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final category = value['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
    });

    return categories.toList()..sort();
  }

  void _filterCareers(String query) {
    setState(() {
      Map<String, dynamic> categoryFiltered;
      if (_selectedCategory == 'All') {
        categoryFiltered = _careersData;
      } else {
        categoryFiltered = {};
        _careersData.forEach((key, value) {
          if (value is Map<String, dynamic> &&
              value['category'] == _selectedCategory) {
            categoryFiltered[key] = value;
          }
        });
      }

      _filteredCareers = _searchCareers(categoryFiltered, query);
    });
  }

  Map<String, dynamic> _searchCareers(
      Map<String, dynamic> careers, String query) {
    if (query.isEmpty) {
      return careers;
    }

    final filteredCareers = <String, dynamic>{};
    final searchQuery = query.toLowerCase();

    careers.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final title = (value['title'] as String? ?? '').toLowerCase();
        final description =
            (value['description'] as String? ?? '').toLowerCase();
        final category = (value['category'] as String? ?? '').toLowerCase();

        if (title.contains(searchQuery) ||
            description.contains(searchQuery) ||
            category.contains(searchQuery)) {
          filteredCareers[key] = value;
        }
      }
    });

    return filteredCareers;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F8F8);
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFFFFD700); // Golden color

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background with sparkles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Update sparkle positions
                for (final sparkle in _sparkles) {
                  sparkle.update();
                }
                return CustomPaint(
                  painter: SparkleParticlePainter(
                    sparkles: _sparkles,
                    darkMode: isDark,
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: accentColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Your Future Pathway',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: 0.2, end: 0),
                      ),
                    ],
                  ),
                ),

                // Inspirational quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Discover the step-by-step journey to your dream career',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: textColor.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                ),

                const SizedBox(height: 20),

                // Search bar with animated golden border
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search for your dream career...',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: accentColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.white10,
                      ),
                      onChanged: _filterCareers,
                    ),
                  ).animate().fadeIn(delay: 400.ms).shimmer(duration: 1500.ms),
                ),

                const SizedBox(height: 16),

                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildFilterChip('All', textColor, accentColor),
                      ..._categories.map((category) {
                        return _buildFilterChip(
                            category, textColor, accentColor);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Content area
                Expanded(
                  child: _isLoading
                      ? _buildLoadingIndicator(accentColor)
                      : _buildCareerVisualization(
                          accentColor, textColor, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            strokeWidth: 3,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1000.ms),
          const SizedBox(height: 24),
          Text(
            'Building your future roadmap...',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 300.ms).shimmer(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, Color textColor, Color accentColor) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.black : textColor.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: accentColor,
        backgroundColor: accentColor.withOpacity(0.1),
        side: BorderSide(
          color: isSelected ? accentColor : accentColor.withOpacity(0.3),
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _filterCareers(_searchController.text);
          });
        },
      ).animate().fadeIn(
          delay: Duration(
              milliseconds: 100 * math.max(0, _categories.indexOf(category)))),
    );
  }

  Widget _buildCareerVisualization(
      Color accentColor, Color textColor, bool isDark) {
    if (_filteredCareers.isEmpty) {
      return Center(
        child: Text(
          'No careers found matching your search',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredCareers.length,
      itemBuilder: (context, index) {
        final careerId = _filteredCareers.keys.elementAt(index);
        final career = _filteredCareers[careerId];

        final title = career['title'] as String? ?? 'Unknown Career';
        final description = career['description'] as String? ?? '';
        final category = career['category'] as String? ?? 'Uncategorized';
        final icon = career['icon'] as String? ?? '💼';

        return _buildCareerCard(
          careerId,
          title,
          description,
          category,
          icon,
          accentColor,
          textColor,
          isDark,
          index,
        );
      },
    );
  }

  Widget _buildCareerCard(
    String careerId,
    String title,
    String description,
    String category,
    String icon,
    Color accentColor,
    Color textColor,
    bool isDark,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CareerDetailScreen(
              careerId: careerId,
              careerData: _careersData[careerId],
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: accentColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colorful gradient header with icon
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(category, accentColor),
                    _getCategoryColor(category, accentColor).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.05, 1.05),
                        duration: 2000.ms),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _getCategoryColor(category, accentColor)
                            .withOpacity(0.2),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getCategoryColor(category, accentColor),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 100 * index))
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
    );
  }

  Color _getCategoryColor(String category, Color defaultColor) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Colors.blue;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.green;
      case 'business':
        return Colors.orange;
      case 'arts':
        return Colors.purple;
      case 'science':
        return Colors.teal;
      case 'engineering':
        return Colors.amber;
      default:
        return defaultColor;
    }
  }
}
