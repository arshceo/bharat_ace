import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});

  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  int selectedCategory = 0;
  final PageController _pageController = PageController();

  final List<String> categories = [
    'All Courses',
    'Computer Science',
    'AI & ML',
    'Web Development',
    'IoT & Hardware'
  ];

  final List<Course> allCourses = [
    // Computer Science Courses
    Course(
      title: 'Data Structures & Algorithms',
      category: 'Computer Science',
      level: 'Intermediate',
      duration: '12 weeks',
      price: 500,
      rating: 4.8,
      students: 1250,
      icon: Icons.account_tree,
      color: const Color(0xFF667EEA),
      description: 'Master the fundamentals of DSA',
      isLocked: false,
    ),
    Course(
      title: 'Object-Oriented Programming',
      category: 'Computer Science',
      level: 'Beginner',
      duration: '8 weeks',
      price: 300,
      rating: 4.6,
      students: 980,
      icon: Icons.code,
      color: const Color(0xFF764BA2),
      description: 'Learn OOP concepts with Java',
      isLocked: false,
    ),
    Course(
      title: 'Database Management Systems',
      category: 'Computer Science',
      level: 'Intermediate',
      duration: '10 weeks',
      price: 400,
      rating: 4.7,
      students: 760,
      icon: Icons.storage,
      color: const Color(0xFF667EEA),
      description: 'Master SQL and database design',
      isLocked: true,
    ),

    // AI & ML Courses
    Course(
      title: 'Machine Learning Fundamentals',
      category: 'AI & ML',
      level: 'Beginner',
      duration: '14 weeks',
      price: 600,
      rating: 4.9,
      students: 2100,
      icon: Icons.psychology,
      color: const Color(0xFFFF6B6B),
      description: 'Start your ML journey',
      isLocked: false,
    ),
    Course(
      title: 'Deep Learning with Neural Networks',
      category: 'AI & ML',
      level: 'Advanced',
      duration: '16 weeks',
      price: 800,
      rating: 4.8,
      students: 890,
      icon: Icons.bubble_chart,
      color: const Color(0xFF4ECDC4),
      description: 'Build advanced neural networks',
      isLocked: true,
    ),
    Course(
      title: 'Computer Vision',
      category: 'AI & ML',
      level: 'Advanced',
      duration: '12 weeks',
      price: 700,
      rating: 4.7,
      students: 650,
      icon: Icons.visibility,
      color: const Color(0xFFFF6B6B),
      description: 'Image processing and analysis',
      isLocked: true,
    ),
    Course(
      title: 'Natural Language Processing',
      category: 'AI & ML',
      level: 'Intermediate',
      duration: '10 weeks',
      price: 550,
      rating: 4.6,
      students: 720,
      icon: Icons.chat,
      color: const Color(0xFF4ECDC4),
      description: 'Process and understand text',
      isLocked: true,
    ),

    // Web Development Courses
    Course(
      title: 'HTML, CSS & JavaScript',
      category: 'Web Development',
      level: 'Beginner',
      duration: '6 weeks',
      price: 200,
      rating: 4.5,
      students: 3200,
      icon: Icons.web,
      color: const Color(0xFF45B7D1),
      description: 'Foundation of web development',
      isLocked: false,
    ),
    Course(
      title: 'React.js Development',
      category: 'Web Development',
      level: 'Intermediate',
      duration: '10 weeks',
      price: 450,
      rating: 4.8,
      students: 1800,
      icon: Icons.code,
      color: const Color(0xFF96CEB4),
      description: 'Build modern web applications',
      isLocked: true,
    ),
    Course(
      title: 'Node.js & Express',
      category: 'Web Development',
      level: 'Intermediate',
      duration: '8 weeks',
      price: 400,
      rating: 4.7,
      students: 1200,
      icon: Icons.dns,
      color: const Color(0xFF45B7D1),
      description: 'Backend development mastery',
      isLocked: true,
    ),
    Course(
      title: 'Full Stack MERN',
      category: 'Web Development',
      level: 'Advanced',
      duration: '20 weeks',
      price: 900,
      rating: 4.9,
      students: 540,
      icon: Icons.layers,
      color: const Color(0xFF96CEB4),
      description: 'Complete web development stack',
      isLocked: true,
    ),

    // IoT & Hardware Courses
    Course(
      title: 'Arduino Programming',
      category: 'IoT & Hardware',
      level: 'Beginner',
      duration: '6 weeks',
      price: 250,
      rating: 4.4,
      students: 890,
      icon: Icons.memory,
      color: const Color(0xFFFECA57),
      description: 'Start with Arduino basics',
      isLocked: false,
    ),
    Course(
      title: 'Raspberry Pi Projects',
      category: 'IoT & Hardware',
      level: 'Intermediate',
      duration: '8 weeks',
      price: 350,
      rating: 4.6,
      students: 620,
      icon: Icons.developer_board,
      color: const Color(0xFFFF9FF3),
      description: 'Build amazing Pi projects',
      isLocked: true,
    ),
    Course(
      title: 'IoT System Design',
      category: 'IoT & Hardware',
      level: 'Advanced',
      duration: '12 weeks',
      price: 600,
      rating: 4.7,
      students: 340,
      icon: Icons.device_hub,
      color: const Color(0xFFFECA57),
      description: 'Design connected systems',
      isLocked: true,
    ),
    Course(
      title: 'Sensor Integration',
      category: 'IoT & Hardware',
      level: 'Intermediate',
      duration: '7 weeks',
      price: 300,
      rating: 4.5,
      students: 480,
      icon: Icons.sensors,
      color: const Color(0xFFFF9FF3),
      description: 'Work with various sensors',
      isLocked: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Course> get filteredCourses {
    if (selectedCategory == 0) return allCourses;
    return allCourses
        .where((course) => course.category == categories[selectedCategory])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                _buildCategoryTabs(),
                _buildCoursesGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
          ),
          child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkBackground,
                AppColors.darkBackground.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated sparkles
              ...List.generate(
                8,
                (index) => AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    return Positioned(
                      left: 30.0 + (index * 45),
                      top: 40 +
                          (sin((_sparkleController.value * 2 * pi) + index) *
                              20),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: [
                            AppColors.primaryPurple,
                            AppColors.accentGreen,
                            AppColors.accentOrange,
                            Colors.purple,
                          ][index % 4]
                              .withOpacity(
                            0.3 +
                                (sin((_sparkleController.value * 2 * pi) +
                                            index) *
                                        0.4)
                                    .abs(),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.primaryPurple,
                  AppColors.accentGreen,
                  AppColors.accentOrange,
                ],
              ).createShader(bounds),
              child: const Text(
                'Unlock Your Potential',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: Text(
              'Choose from our premium courses and start your learning journey',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _buildCoinsDisplay(),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    return SlideInLeft(
      duration: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accentOrange.withOpacity(0.2),
              AppColors.accentOrange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Coins',
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '1,250', // This would come from user data
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.accentGreen
                        ],
                      )
                    : null,
                color:
                    isSelected ? null : AppColors.surfaceDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.textPrimary.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      ),
    );
  }

  Widget _buildCoursesGrid() {
    final courses = filteredCourses;

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.69,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(course, index);
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course, int index) {
    return SlideInUp(
      duration: Duration(milliseconds: 600 + (index * 100)),
      child: GestureDetector(
        onTap: () {
          if (course.isLocked) {
            _showUnlockDialog(course);
          } else {
            _navigateToCourse(course);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                course.color.withOpacity(0.1),
                course.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: course.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Course content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course icon and lock status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: course.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            course.icon,
                            color: course.color,
                            size: 24,
                          ),
                        ),
                        if (course.isLocked)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Course title
                    Text(
                      course.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Course description
                    Text(
                      course.description,
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Course details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getLevelColor(course.level)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course.level,
                                style: TextStyle(
                                  color: _getLevelColor(course.level),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  course.rating.toString(),
                                  style: TextStyle(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.8),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course.duration,
                              style: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: AppColors.accentOrange,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${course.price}',
                                  style: const TextStyle(
                                    color: AppColors.accentOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Shimmer effect for locked courses
              if (course.isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.surfaceDark.withOpacity(0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return AppColors.accentGreen;
      case 'intermediate':
        return AppColors.accentOrange;
      case 'advanced':
        return Colors.red;
      default:
        return AppColors.primaryPurple;
    }
  }

  void _showUnlockDialog(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: course.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(course.icon, color: course.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unlock Course',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cost to Unlock',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${course.price} Coins',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement unlock logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Course unlock feature coming soon!'),
                  backgroundColor: AppColors.accentOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Unlock Now'),
          ),
        ],
      ),
    );
  }

  void _navigateToCourse(Course course) {
    // TODO: Navigate to course detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${course.title}...'),
        backgroundColor: course.color,
      ),
    );
  }
}

class Course {
  final String title;
  final String category;
  final String level;
  final String duration;
  final int price;
  final double rating;
  final int students;
  final IconData icon;
  final Color color;
  final String description;
  final bool isLocked;

  Course({
    required this.title,
    required this.category,
    required this.level,
    required this.duration,
    required this.price,
    required this.rating,
    required this.students,
    required this.icon,
    required this.color,
    required this.description,
    required this.isLocked,
  });
}
