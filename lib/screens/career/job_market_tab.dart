import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A helper widget for the Job Market Tab in the Career Detail Screen
class JobMarketTab {
  static Widget build(
    Map<String, dynamic> careerData,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    // Extract job market information if available
    Map<String, dynamic>? jobMarket;
    Map<String, dynamic>? topCompanies;
    Map<String, dynamic>? jobLocations;

    List<Map<String, dynamic>> productCompanies = [];
    List<Map<String, dynamic>> serviceCompanies = [];
    List<Map<String, dynamic>> startups = [];
    List<Map<String, dynamic>> locationsList = [];

    List<Map<String, dynamic>> successStories = [];
    List<Map<String, dynamic>> alternativePaths = [];
    List<Map<String, dynamic>> challenges = [];
    Map<String, List<String>> dayInLifeData = {};

    if (careerData['job_market'] is Map<String, dynamic>) {
      jobMarket = careerData['job_market'] as Map<String, dynamic>;

      // Extract top companies
      if (jobMarket['top_companies'] is Map<String, dynamic>) {
        topCompanies = jobMarket['top_companies'] as Map<String, dynamic>;

        // Product companies
        if (topCompanies['product_companies'] is List) {
          for (final company in topCompanies['product_companies']) {
            if (company is Map<String, dynamic>) {
              productCompanies.add(company);
            }
          }
        }

        // Service companies
        if (topCompanies['service_companies'] is List) {
          for (final company in topCompanies['service_companies']) {
            if (company is Map<String, dynamic>) {
              serviceCompanies.add(company);
            }
          }
        }

        // Startups
        if (topCompanies['startups'] is List) {
          for (final company in topCompanies['startups']) {
            if (company is Map<String, dynamic>) {
              startups.add(company);
            }
          }
        }
      }

      // Extract job locations
      if (jobMarket['job_locations'] is Map<String, dynamic>) {
        jobLocations = jobMarket['job_locations'] as Map<String, dynamic>;
        jobLocations.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            value['name'] = key.toString().toUpperCase();
            locationsList.add(value);
          }
        });
      }
    }

    // Extract success stories
    if (careerData['success_stories'] is List) {
      for (final story in careerData['success_stories']) {
        if (story is Map<String, dynamic>) {
          successStories.add(story);
        }
      }
    }

    // Extract alternative paths
    if (careerData['alternative_paths'] is List) {
      for (final path in careerData['alternative_paths']) {
        if (path is Map<String, dynamic>) {
          alternativePaths.add(path);
        }
      }
    }

    // Extract challenges and solutions
    if (careerData['challenges_solutions'] is Map<String, dynamic> &&
        careerData['challenges_solutions']['common_challenges'] is List) {
      for (final challenge in careerData['challenges_solutions']
          ['common_challenges']) {
        if (challenge is Map<String, dynamic>) {
          challenges.add(challenge);
        }
      }
    }

    // Extract day in life information
    if (careerData['day_in_life'] is Map<String, dynamic>) {
      final dayInLife = careerData['day_in_life'] as Map<String, dynamic>;
      dayInLife.forEach((key, value) {
        if (value is List) {
          dayInLifeData[key] = [];
          for (final item in value) {
            if (item is String) {
              dayInLifeData[key]!.add(item);
            }
          }
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top companies section
        if (productCompanies.isNotEmpty ||
            serviceCompanies.isNotEmpty ||
            startups.isNotEmpty) ...[
          _buildSectionHeader('Top Companies', accentColor, textColor),

          // Product companies
          if (productCompanies.isNotEmpty) ...[
            _buildCompanyTypeHeader('Product Companies', textColor),
            ...productCompanies.map((company) => _buildCompanyCard(
                  company,
                  accentColor,
                  textColor,
                  isDark,
                  Colors.blue,
                )),
            const SizedBox(height: 16),
          ],

          // Service companies
          if (serviceCompanies.isNotEmpty) ...[
            _buildCompanyTypeHeader('Service Companies', textColor),
            ...serviceCompanies.map((company) => _buildCompanyCard(
                  company,
                  accentColor,
                  textColor,
                  isDark,
                  Colors.green,
                )),
            const SizedBox(height: 16),
          ],

          // Startups
          if (startups.isNotEmpty) ...[
            _buildCompanyTypeHeader('Startups & Growth Companies', textColor),
            ...startups.map((company) => _buildCompanyCard(
                  company,
                  accentColor,
                  textColor,
                  isDark,
                  Colors.orange,
                )),
            const SizedBox(height: 24),
          ],
        ],

        // Job locations
        if (locationsList.isNotEmpty) ...[
          _buildSectionHeader('Top Job Locations', accentColor, textColor),
          _buildLocationsCard(locationsList, accentColor, textColor, isDark),
          const SizedBox(height: 24),
        ],

        // Day in life section
        if (dayInLifeData.isNotEmpty) ...[
          _buildSectionHeader('Day in the Life', accentColor, textColor),
          _buildDayInLifeCard(dayInLifeData, accentColor, textColor, isDark),
          const SizedBox(height: 24),
        ],

        // Success stories
        if (successStories.isNotEmpty) ...[
          _buildSectionHeader('Success Stories', accentColor, textColor),
          ...successStories.map((story) => _buildSuccessStoryCard(
                story,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // Alternative career paths
        if (alternativePaths.isNotEmpty) ...[
          _buildSectionHeader(
              'Alternative Career Paths', accentColor, textColor),
          ...alternativePaths.map((path) => _buildAlternativePathCard(
                path,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // Challenges and solutions
        if (challenges.isNotEmpty) ...[
          _buildSectionHeader('Challenges & Solutions', accentColor, textColor),
          ...challenges.map((challenge) => _buildChallengeCard(
                challenge,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // If no job market data is available
        if (productCompanies.isEmpty &&
            serviceCompanies.isEmpty &&
            startups.isEmpty &&
            locationsList.isEmpty &&
            successStories.isEmpty &&
            alternativePaths.isEmpty &&
            challenges.isEmpty &&
            dayInLifeData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No job market information available for this career',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // Section header widget
  static Widget _buildSectionHeader(
      String title, Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  // Company type header
  static Widget _buildCompanyTypeHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // Company card
  static Widget _buildCompanyCard(
    Map<String, dynamic> company,
    Color accentColor,
    Color textColor,
    bool isDark,
    Color tagColor,
  ) {
    final name = company['name'] as String? ?? 'Unnamed Company';
    final salaryRange =
        company['salary_range'] as String? ?? 'Salary not specified';

    List<String> locations = [];
    if (company['locations'] is List) {
      for (final loc in company['locations']) {
        if (loc is String) {
          locations.add(loc);
        }
      }
    }

    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: textColor.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    salaryRange,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (locations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: locations
                          .map((loc) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  loc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tagColor,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Job locations card
  static Widget _buildLocationsCard(
    List<Map<String, dynamic>> locations,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...locations.map((location) {
              final name = location['name'] as String? ?? 'Unknown';
              final opportunities =
                  location['opportunities'] as String? ?? 'Medium';
              final costOfLiving =
                  location['cost_of_living'] as String? ?? 'Medium';
              final avgSalary =
                  location['average_salary'] as String? ?? 'Not specified';
              final majorCompanies = location['major_companies'] as int? ?? 0;

              // Determine opportunity color based on level
              final opportunityLevel = opportunities.toLowerCase();
              Color opportunityColor;
              if (opportunityLevel == 'highest' ||
                  opportunityLevel == 'very high') {
                opportunityColor = Colors.green;
              } else if (opportunityLevel == 'high') {
                opportunityColor = Colors.lightGreen;
              } else if (opportunityLevel == 'medium') {
                opportunityColor = Colors.orange;
              } else {
                opportunityColor = Colors.grey;
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: opportunityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          opportunities,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: opportunityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                avgSalary,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.home,
                              size: 16,
                              color: textColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Cost: $costOfLiving',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$majorCompanies major companies',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (location != locations.last) const Divider(height: 24),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Success story card
  static Widget _buildSuccessStoryCard(
    Map<String, dynamic> story,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final name = story['name'] as String? ?? 'Unnamed Professional';
    final position = story['position'] as String? ?? 'Unknown Position';
    final background = story['background'] as String? ?? 'Unknown Background';
    final journey = story['journey'] as String? ?? '';
    final keyLesson = story['key_lesson'] as String? ?? '';

    return Card(
      elevation: 3,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar placeholder
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.2),
                  radius: 24,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        position,
                        style: TextStyle(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (background.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      background,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (journey.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.timeline,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      journey,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (keyLesson.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Key Lesson: $keyLesson',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Alternative career path card
  static Widget _buildAlternativePathCard(
    Map<String, dynamic> pathData,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final path = pathData['path'] as String? ?? 'Alternative Path';
    final description = pathData['description'] as String? ?? '';
    final timeline = pathData['timeline'] as String? ?? '';

    List<String> requirements = [];
    if (pathData['requirements'] is List) {
      for (final req in pathData['requirements']) {
        if (req is String) {
          requirements.add(req);
        }
      }
    }

    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              path,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ],
            if (timeline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timelapse,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      timeline,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Requirements:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...requirements
                  .map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  // Challenge and solution card
  static Widget _buildChallengeCard(
    Map<String, dynamic> challenge,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final challengeText =
        challenge['challenge'] as String? ?? 'Unknown Challenge';
    final solution = challenge['solution'] as String? ?? '';

    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challengeText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            if (solution.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      solution,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Day in life card
  static Widget _buildDayInLifeCard(
    Map<String, List<String>> dayInLife,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...dayInLife.entries.map((entry) {
              final level = _formatCareerLevel(entry.key);
              final activities = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: accentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activities.map((activity) {
                    // Extract time if it follows a pattern like "9:00 AM - "
                    final timeRegex = RegExp(r'(\d+:\d+\s+[AP]M)\s+-\s+');
                    final timeMatch = timeRegex.firstMatch(activity);
                    String time = '';
                    String task = activity;

                    if (timeMatch != null) {
                      time = timeMatch.group(1) ?? '';
                      task = activity.substring(timeMatch.end);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (time.isNotEmpty)
                            Container(
                              width: 80,
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6, right: 72),
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              task,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (entry.key != dayInLife.keys.last)
                    const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Format career level for display
  static String _formatCareerLevel(String level) {
    final words = level.split('_');
    final capitalizedWords = words.map((word) =>
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '');
    return capitalizedWords.join(' ') + ' Professional';
  }
}
