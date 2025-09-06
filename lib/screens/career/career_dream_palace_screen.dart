import 'package:bharat_ace/core/services/career_json_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'starfield_painter.dart';

class CareerDreamPalaceScreen extends StatefulWidget {
  const CareerDreamPalaceScreen({super.key});

  @override
  State<CareerDreamPalaceScreen> createState() =>
      _CareerDreamPalaceScreenState();
}

class _CareerDreamPalaceScreenState extends State<CareerDreamPalaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCareerId;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  Map<String, dynamic> _careersData = {};
  Map<String, dynamic> _filteredCareers = {};
  List<String> _categories = [];
  bool _isLoading = true;
  bool _showFullRoadmap = false;

  // For particles animation
  final List<Offset> _particles = List.generate(50, (index) => Offset.zero);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeParticles();
    _checkAssets();
    _loadCareerData();
  }

  Future<void> _checkAssets() async {
    try {
      print("Checking assets directory structure...");

      // Try to load a different asset file to see if assets are working in general
      try {
        await rootBundle.loadString('.env');
        print("Successfully loaded .env file");
      } catch (e) {
        print("Could not load .env file: $e");
      }

      // Check specifically for career directory
      try {
        await rootBundle.loadString('assets/career/career_database.json');
        print("Successfully loaded career_database.json directly!");
      } catch (e) {
        print("Could not directly load career_database.json: $e");
      }

      // Check with different path formats
      try {
        await rootBundle.loadString('assets/career/career_database.json');
        print("Path format 1 works");
      } catch (_) {}

      try {
        await rootBundle.loadString('./assets/career/career_database.json');
        print("Path format 2 works");
      } catch (_) {}

      try {
        await rootBundle.loadString('/assets/career/career_database.json');
        print("Path format 3 works");
      } catch (_) {}
    } catch (e) {
      print("Error checking assets: $e");
    }
  }

  void _initializeParticles() {
    for (int i = 0; i < _particles.length; i++) {
      _particles[i] = Offset(
        (1000 * i / _particles.length).toDouble(),
        (500 * i / _particles.length).toDouble(),
      );
    }
  }

  Future<void> _loadCareerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting to load career data...');
      final data = await CareerJsonService.loadCareersData();
      print('Career data loaded: ${data.length} careers found');

      if (data.isEmpty) {
        print('WARNING: Career data is empty! Check JSON file structure.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Career data is empty. Please check the JSON file structure.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Log a sample of the data
        print('Sample data: ${data.keys.take(3).toList()}');
      }

      setState(() {
        _careersData = data;
        _filteredCareers = data;
        _categories = _getCareerCategories(data);
        print('Categories found: $_categories');
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
        // Set empty data to prevent null errors
        _careersData = {};
        _filteredCareers = {};
        _categories = [];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCareers(String query) {
    setState(() {
      Map<String, dynamic> categoryFiltered;
      if (_selectedCategory == 'All') {
        categoryFiltered = _careersData;
      } else {
        // Manual category filtering
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

  void _selectCareer(String careerId) {
    setState(() {
      _selectedCareerId = careerId;
      _showFullRoadmap = true;
    });
  }

  void _goBackToGrid() {
    setState(() {
      if (_showFullRoadmap) {
        _showFullRoadmap = false;
      } else {
        _selectedCareerId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = const Color(0xFFFFD700); // Golden color

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated particles in the background
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(
                particles: _particles,
                accentColor: accentColor,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: accentColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Career Dream Palace',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: 0.2, end: 0),
                    ],
                  ),
                ),

                // Inspirational tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Discover your perfect career path with magical guidance',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: textColor.withOpacity(0.8),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                ),

                const SizedBox(height: 24),

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
                if (!_showFullRoadmap)
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

                if (!_showFullRoadmap) const SizedBox(height: 16),

                // Content area
                Expanded(
                  child: _isLoading
                      ? _buildLoadingIndicator(accentColor)
                      : (_selectedCareerId == null
                          ? _buildCareerGrid(accentColor, textColor, isDark)
                          : (_showFullRoadmap
                              ? _buildFullRoadmap(_selectedCareerId!,
                                  accentColor, textColor, isDark)
                              : _buildCareerOverview(_selectedCareerId!,
                                  accentColor, textColor, isDark))),
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
          ),
          const SizedBox(height: 24),
          Text(
            'Loading career data...',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            color: isSelected ? Colors.black : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _filterCareers(_searchController.text);
          });
        },
        backgroundColor: Colors.transparent,
        selectedColor: accentColor,
        side: BorderSide(
          color: isSelected ? accentColor : accentColor.withOpacity(0.3),
        ),
        shape: StadiumBorder(),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCareerGrid(Color accentColor, Color textColor, bool isDark) {
    if (_filteredCareers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: accentColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No careers match your search',
              style: TextStyle(
                fontSize: 18,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or categories',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    final careerIds = _filteredCareers.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: careerIds.length,
      itemBuilder: (context, index) {
        final careerId = careerIds[index];
        final careerData = _filteredCareers[careerId];
        return _buildCareerCard(
            careerId, careerData, accentColor, textColor, isDark, index);
      },
    );
  }

  Widget _buildCareerCard(String careerId, Map<String, dynamic>? careerData,
      Color accentColor, Color textColor, bool isDark, int index) {
    if (careerData == null) return const SizedBox();

    // Extract data from the career map
    final title = careerData['title'] as String? ?? 'Unknown Career';
    // Use 'description' field from the JSON instead of 'shortDescription'
    final shortDescription =
        careerData['description'] as String? ?? 'No description available';
    final category = careerData['category'] as String? ?? 'Uncategorized';

    return GestureDetector(
      onTap: () => _selectCareer(careerId),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              isDark ? Colors.black : Colors.white,
              isDark ? Color(0xFF1A1A1A) : Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Ensures column takes minimum space needed
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon would be loaded from assets if available
            Icon(
              _getCareerIcon(title),
              size: 40, // Slightly smaller icon to save space
              color: accentColor,
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, // Slightly smaller text
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6), // Reduced spacing
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0), // Less padding
              child: Text(
                shortDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11, // Smaller text
                  color: textColor.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4), // Less padding
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: accentColor.withOpacity(0.2),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w500,
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

  Widget _buildCareerOverview(
      String careerId, Color accentColor, Color textColor, bool isDark) {
    final careerData = _careersData[careerId];
    if (careerData == null) return const SizedBox();

    final title = careerData['title'] as String? ?? 'Unknown Career';
    // Use 'description' field for the detailed description
    final description = careerData['description'] as String? ??
        'No detailed description available';
    final category = careerData['category'] as String? ?? 'Uncategorized';

    // Handle the different salary structure in the actual JSON
    String salary = 'N/A';
    if (careerData['salary_info'] is Map<String, dynamic>) {
      final salaryInfo = careerData['salary_info'] as Map<String, dynamic>;
      if (salaryInfo['mid_level'] is Map<String, dynamic>) {
        final midLevel = salaryInfo['mid_level'] as Map<String, dynamic>;
        final min = midLevel['min']?.toString() ?? '';
        final max = midLevel['max']?.toString() ?? '';
        if (min.isNotEmpty && max.isNotEmpty) {
          salary = '₹${min}-${max} per ${midLevel['per'] ?? 'annum'}';
        }
      }
    }

    // Default avatar image if 'imageUrl' doesn't exist
    final imageUrl = careerData['imageUrl'] as String? ??
        'assets/avatars/default_avatar.png';

    // Get education and skills data from the new JSON structure
    List<dynamic> educationSteps = [];
    List<dynamic> skills = [];

    // Extract education steps from academic_roadmap if available
    if (careerData['academic_roadmap'] is Map<String, dynamic>) {
      // Create education steps from academic roadmap data
      educationSteps = [
        {
          'title': 'Academic Requirements',
          'description': 'Education pathway for this career'
        }
      ];
    }

    // Extract skills from required_skills if available
    if (careerData['required_skills'] is Map<String, dynamic>) {
      final requiredSkills =
          careerData['required_skills'] as Map<String, dynamic>;

      // Get technical skills
      final technicalSkills =
          requiredSkills['technical_skills'] as List<dynamic>? ?? [];

      // Get soft skills
      final softSkills = requiredSkills['soft_skills'] as List<dynamic>? ?? [];

      // Combine and transform skills into the expected format
      skills = [
        ...technicalSkills.map((skill) => {
              'name': skill['skill'] as String? ?? 'Unknown skill',
              'level': skill['importance'] == 'Critical'
                  ? 'advanced'
                  : 'intermediate',
              'type': 'technical'
            }),
        ...softSkills.map((skill) => {
              'name': skill['skill'] as String? ?? 'Unknown skill',
              'level': skill['importance'] == 'Critical'
                  ? 'advanced'
                  : 'intermediate',
              'type': 'soft'
            })
      ];
    }

    return Column(
      children: [
        // Header with navigation
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: accentColor),
                onPressed: _goBackToGrid,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.fullscreen, color: accentColor),
                onPressed: () {
                  setState(() {
                    _showFullRoadmap = true;
                  });
                },
                tooltip: 'View Full Roadmap',
              ),
            ],
          ),
        ),

        // Career overview content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Career image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: accentColor.withOpacity(0.2),
                            child: Icon(
                              _getCareerIcon(title),
                              size: 40,
                              color: accentColor,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Basic info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: accentColor.withOpacity(0.2),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 18, color: accentColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Median: $salary',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Roadmap preview
                _buildSectionHeader('Roadmap Preview', accentColor),
                Text(
                  'Tap on the "Full Screen" button to view the complete roadmap',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                // Preview of education steps
                if (educationSteps.isNotEmpty) ...[
                  Text(
                    'Education Path:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.black12 : Colors.white,
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < min(3, educationSteps.length); i++)
                          _buildPreviewStep(
                            "${i + 1}. ${educationSteps[i]['title'] ?? 'Education Step'}",
                            textColor,
                            accentColor,
                          ),
                        if (educationSteps.length > 3)
                          Text(
                            'And ${educationSteps.length - 3} more steps...',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Preview of skills
                if (skills.isNotEmpty) ...[
                  Text(
                    'Key Skills:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < min(6, skills.length); i++)
                        Chip(
                          backgroundColor: accentColor.withOpacity(0.1),
                          side: BorderSide(
                            color: accentColor.withOpacity(0.3),
                          ),
                          label: Text(
                            skills[i]['name'] ?? 'Skill',
                            style: TextStyle(
                              color: accentColor,
                            ),
                          ),
                        ),
                      if (skills.length > 6)
                        Chip(
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: accentColor.withOpacity(0.3),
                          ),
                          label: Text(
                            '+${skills.length - 6} more',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // View full roadmap button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFullRoadmap = true;
                      });
                    },
                    icon: Icon(Icons.fullscreen, color: Colors.black),
                    label: Text(
                      'View Full Roadmap',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep(String text, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullRoadmap(
      String careerId, Color accentColor, Color textColor, bool isDark) {
    final careerData = _careersData[careerId];
    if (careerData == null) return const SizedBox();

    final title = careerData['title'] as String? ?? 'Unknown Career';

    // Set up education steps, skills, and career path data from new JSON structure
    List<dynamic> educationSteps = [];
    List<dynamic> skills = [];
    List<dynamic> careerPath = [];

    // Extract education data
    if (careerData['academic_roadmap'] is Map<String, dynamic>) {
      // If no specific higher education found, create a generic entry
      educationSteps = [
        {
          'title': 'Academic Requirements',
          'description': 'Education pathway for this career',
          'duration': 'Varies'
        }
      ];
    }

    // Extract skills
    if (careerData['required_skills'] is Map<String, dynamic>) {
      final requiredSkills =
          careerData['required_skills'] as Map<String, dynamic>;

      // Get technical skills
      final technicalSkills =
          requiredSkills['technical_skills'] as List<dynamic>? ?? [];

      // Get soft skills
      final softSkills = requiredSkills['soft_skills'] as List<dynamic>? ?? [];

      // Combine and transform skills into the expected format
      skills = [
        ...technicalSkills.map((skill) => {
              'name': skill['skill'] as String? ?? 'Unknown skill',
              'level': skill['importance'] == 'Critical'
                  ? 'advanced'
                  : 'intermediate',
              'type': 'technical'
            }),
        ...softSkills.map((skill) => {
              'name': skill['skill'] as String? ?? 'Unknown skill',
              'level': skill['importance'] == 'Critical'
                  ? 'advanced'
                  : 'intermediate',
              'type': 'soft'
            })
      ];
    }

    // Extract career path
    if (careerData['salary_info'] is Map<String, dynamic>) {
      final salaryInfo = careerData['salary_info'] as Map<String, dynamic>;

      careerPath = [];

      // Add entry level if available
      if (salaryInfo['entry_level'] is Map) {
        final entry = salaryInfo['entry_level'] as Map<String, dynamic>;
        careerPath.add({
          'title': 'Entry Level',
          'experience': '0-2 years',
          'salary':
              '₹${entry['min'] ?? "0"}-${entry['max'] ?? "0"} per ${entry['per'] ?? 'annum'}',
          'description': 'Starting position in the career'
        });
      }

      // Add mid level if available
      if (salaryInfo['mid_level'] is Map) {
        final mid = salaryInfo['mid_level'] as Map<String, dynamic>;
        careerPath.add({
          'title': 'Mid Level',
          'experience': '3-5 years',
          'salary':
              '₹${mid['min'] ?? "0"}-${mid['max'] ?? "0"} per ${mid['per'] ?? 'annum'}',
          'description': 'Intermediate position with more responsibility'
        });
      }

      // Add senior level if available
      if (salaryInfo['senior_level'] is Map) {
        final senior = salaryInfo['senior_level'] as Map<String, dynamic>;
        careerPath.add({
          'title': 'Senior Level',
          'experience': '5+ years',
          'salary':
              '₹${senior['min'] ?? "0"}-${senior['max'] ?? "0"} per ${senior['per'] ?? 'annum'}',
          'description': 'Leadership position with significant experience'
        });
      }
    }

    return Column(
      children: [
        // Header with navigation
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: accentColor),
                onPressed: _goBackToGrid,
              ),
              Expanded(
                child: Text(
                  '$title Career Roadmap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.fullscreen_exit, color: accentColor),
                onPressed: () {
                  setState(() {
                    _showFullRoadmap = false;
                  });
                },
                tooltip: 'Exit Full Screen',
              ),
            ],
          ),
        ),

        // Roadmap content
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Tab bar
                TabBar(
                  labelColor: accentColor,
                  unselectedLabelColor: textColor.withOpacity(0.5),
                  indicatorColor: accentColor,
                  tabs: const [
                    Tab(text: 'EDUCATION'),
                    Tab(text: 'SKILLS'),
                    Tab(text: 'CAREER PATH'),
                  ],
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      // Education tab
                      _buildEducationRoadmap(
                          educationSteps, accentColor, textColor, isDark),

                      // Skills tab
                      _buildSkillsRoadmap(
                          skills, accentColor, textColor, isDark),

                      // Career path tab
                      _buildCareerPathRoadmap(
                          careerPath, accentColor, textColor, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationRoadmap(
      List<dynamic> steps, Color accentColor, Color textColor, bool isDark) {
    if (steps.isEmpty) {
      return Center(
        child: Text(
          'No education path data available',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final title = step['title'] as String? ?? 'Step ${index + 1}';
        final description =
            step['description'] as String? ?? 'No description available';
        final duration = step['duration'] as String? ?? 'Varies';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step number and title
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Duration
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildSkillsRoadmap(
      List<dynamic> skills, Color accentColor, Color textColor, bool isDark) {
    if (skills.isEmpty) {
      return Center(
        child: Text(
          'No skills data available',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Organize skills by type
    final technicalSkills = skills
        .where((skill) =>
            skill['type'] == 'technical' || skill['type'] == 'Technical')
        .toList();
    final softSkills = skills
        .where((skill) => skill['type'] == 'soft' || skill['type'] == 'Soft')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technical skills
          if (technicalSkills.isNotEmpty) ...[
            Text(
              'Technical Skills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSkillsGrid(technicalSkills, accentColor, textColor, isDark),
            const SizedBox(height: 32),
          ],

          // Soft skills
          if (softSkills.isNotEmpty) ...[
            Text(
              'Soft Skills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSkillsGrid(softSkills, accentColor, textColor, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsGrid(
      List<dynamic> skills, Color accentColor, Color textColor, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        final name = skill['name'] as String? ?? 'Unknown Skill';
        final level = skill['level'] as String? ?? 'basic';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Ensures minimum vertical space
              children: [
                // Skill name
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Skill level indicator
                _buildSkillLevelIndicator(level, accentColor),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms);
      },
    );
  }

  Widget _buildSkillLevelIndicator(String level, Color accentColor) {
    int filledDots;
    String levelText;

    switch (level.toLowerCase()) {
      case 'basic':
      case 'beginner':
        filledDots = 1;
        levelText = 'Basic';
        break;
      case 'intermediate':
        filledDots = 2;
        levelText = 'Intermediate';
        break;
      case 'advanced':
      case 'expert':
        filledDots = 3;
        levelText = 'Advanced';
        break;
      default:
        filledDots = 1;
        levelText = 'Basic';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < filledDots
                    ? accentColor
                    : accentColor.withOpacity(0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          levelText,
          style: TextStyle(
            fontSize: 12,
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCareerPathRoadmap(List<dynamic> careerPath, Color accentColor,
      Color textColor, bool isDark) {
    if (careerPath.isEmpty) {
      return Center(
        child: Text(
          'No career path data available',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: careerPath.length,
      itemBuilder: (context, index) {
        final step = careerPath[index];
        final title = step['title'] as String? ?? 'Career Stage ${index + 1}';
        final description =
            step['description'] as String? ?? 'No description available';
        final experience = step['experience'] as String? ?? 'Varies';
        final salary = step['salary'] as String? ?? 'Varies';

        return Stack(
          children: [
            // Timeline line
            if (index < careerPath.length - 1)
              Positioned(
                top: 40,
                bottom: 0,
                left: 24,
                child: Container(
                  width: 2,
                  color: accentColor.withOpacity(0.3),
                ),
              ),

            // Career stage card
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.2),
                      border: Border.all(
                        color: accentColor,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Experience and salary
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.work,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        experience,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.attach_money,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        salary,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: (200 * index).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }

  // Helper function to find minimum of two integers
  int min(int a, int b) => a < b ? a : b;

  // Function to get appropriate icons for different careers
  IconData _getCareerIcon(String careerTitle) {
    final title = careerTitle.toLowerCase();

    if (title.contains('engineer') || title.contains('developer')) {
      return Icons.computer;
    } else if (title.contains('doctor') ||
        title.contains('medical') ||
        title.contains('health')) {
      return Icons.medical_services;
    } else if (title.contains('teacher') ||
        title.contains('professor') ||
        title.contains('education')) {
      return Icons.school;
    } else if (title.contains('business') || title.contains('entrepreneur')) {
      return Icons.business;
    } else if (title.contains('artist') || title.contains('design')) {
      return Icons.brush;
    } else if (title.contains('law') || title.contains('legal')) {
      return Icons.gavel;
    } else if (title.contains('finance') || title.contains('account')) {
      return Icons.account_balance;
    } else if (title.contains('science')) {
      return Icons.science;
    } else {
      return Icons.work;
    }
  }

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
