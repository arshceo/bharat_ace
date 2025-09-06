import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A helper widget for the Resources Tab in the Career Detail Screen
class ResourcesTab {
  static Widget build(
    Map<String, dynamic> careerData,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    // Extract learning resources if available
    Map<String, dynamic>? learningResources;
    List<Map<String, dynamic>> freeResources = [];
    List<Map<String, dynamic>> paidResources = [];
    List<Map<String, dynamic>> recommendedBooks = [];
    List<Map<String, dynamic>> certifications = [];

    if (careerData['learning_resources'] is Map) {
      learningResources =
          careerData['learning_resources'] as Map<String, dynamic>;

      // Extract free resources
      if (learningResources['free_resources'] is List) {
        for (final resource in learningResources['free_resources']) {
          if (resource is Map<String, dynamic>) {
            freeResources.add(resource);
          }
        }
      }

      // Extract paid resources
      if (learningResources['paid_resources'] is List) {
        for (final resource in learningResources['paid_resources']) {
          if (resource is Map<String, dynamic>) {
            paidResources.add(resource);
          }
        }
      }

      // Extract books
      if (learningResources['books'] is List) {
        for (final book in learningResources['books']) {
          if (book is Map<String, dynamic>) {
            recommendedBooks.add(book);
          }
        }
      }
    }

    // Extract certifications
    if (careerData['certifications'] is List) {
      for (final cert in careerData['certifications']) {
        if (cert is Map<String, dynamic>) {
          certifications.add(cert);
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Certifications section
        if (certifications.isNotEmpty) ...[
          _buildSectionHeader(
              'Professional Certifications', accentColor, textColor),
          ...certifications.map((cert) => _buildCertificationCard(
                cert,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // Free resources
        if (freeResources.isNotEmpty) ...[
          _buildSectionHeader(
              'Free Learning Resources', accentColor, textColor),
          ...freeResources.map((resource) => _buildFreeResourceCard(
                resource,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // Paid resources
        if (paidResources.isNotEmpty) ...[
          _buildSectionHeader(
              'Premium Courses & Bootcamps', accentColor, textColor),
          ...paidResources.map((resource) => _buildPaidResourceCard(
                resource,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // Books
        if (recommendedBooks.isNotEmpty) ...[
          _buildSectionHeader('Recommended Books', accentColor, textColor),
          ...recommendedBooks.map((book) => _buildBookCard(
                book,
                accentColor,
                textColor,
                isDark,
              )),
          const SizedBox(height: 24),
        ],

        // If no resources are available
        if (certifications.isEmpty &&
            freeResources.isEmpty &&
            paidResources.isEmpty &&
            recommendedBooks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: textColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No learning resources available for this career',
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

  // Card for professional certifications
  static Widget _buildCertificationCard(
    Map<String, dynamic> cert,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final name = cert['name'] as String? ?? 'Unnamed Certification';
    final provider = cert['provider'] as String? ?? 'Unknown Provider';
    final cost = cert['cost'] as String? ?? 'Cost not specified';
    final validity = cert['validity'] as String? ?? 'Unknown validity';
    final importance = cert['importance'] as String? ?? 'Medium';

    final importanceColor = _getImportanceColor(importance);

    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: importanceColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: importanceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    importance,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: importanceColor,
                    ),
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
                    'Provider: $provider',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
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
                          cost,
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
                        Icons.timelapse,
                        size: 16,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Valid for: $validity',
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
          ],
        ),
      ),
    );
  }

  // Card for free online resources
  static Widget _buildFreeResourceCard(
    Map<String, dynamic> resource,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final name = resource['name'] as String? ?? 'Unnamed Resource';
    final type = resource['type'] as String? ?? 'Online Resource';
    final url = resource['url'] as String? ?? '';

    List<String> topics = [];
    if (resource['topics'] is List) {
      for (final topic in resource['topics']) {
        if (topic is String) {
          topics.add(topic);
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
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 20,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Free',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: textColor.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 14,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics
                    .map((topic) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card for paid courses
  static Widget _buildPaidResourceCard(
    Map<String, dynamic> resource,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final name = resource['name'] as String? ?? 'Unnamed Course';
    final cost = resource['cost'] as String? ?? 'Price not specified';
    final duration =
        resource['duration'] as String? ?? 'Duration not specified';
    final hasCertification = resource['certification'] == 'Yes';
    final hasPlacementSupport = resource['placement_support'] == 'Yes';

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
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
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
                          cost,
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
                        Icons.timelapse,
                        size: 16,
                        color: textColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          duration,
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
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasCertification)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Certification',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasPlacementSupport)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.work,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Placement Support',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Card for recommended books
  static Widget _buildBookCard(
    Map<String, dynamic> book,
    Color accentColor,
    Color textColor,
    bool isDark,
  ) {
    final title = book['title'] as String? ?? 'Untitled Book';
    final author = book['author'] as String? ?? 'Unknown Author';
    final price = book['price'] as String? ?? 'Price not specified';
    final importance = book['importance'] as String? ?? 'Medium';

    final importanceColor = _getImportanceColor(importance);

    return Card(
      elevation: 2,
      shadowColor: accentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: importanceColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover placeholder
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  Icons.book,
                  size: 36,
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $author',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: importanceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          importance,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: importanceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
