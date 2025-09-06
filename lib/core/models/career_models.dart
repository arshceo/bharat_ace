class Career {
  final String id;
  final String title;
  final String shortDescription;
  final String longDescription;
  final String iconPath;
  final String category;
  final CareerDetails details;

  Career({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.longDescription,
    required this.iconPath,
    required this.category,
    required this.details,
  });
}

class CareerDetails {
  final MarketOverview marketOverview;
  final List<CareerSkill> requiredSkills;
  final EducationPathway educationPathway;
  final List<CareerPosition> careerProgression;
  final List<String> industryInsights;
  final List<SuccessStory> successStories;

  CareerDetails({
    required this.marketOverview,
    required this.requiredSkills,
    required this.educationPathway,
    required this.careerProgression,
    required this.industryInsights,
    required this.successStories,
  });
}

class MarketOverview {
  final String currentDemand; // Low, Medium, High, Very High
  final String growthProjection; // Percentage or description
  final String salaryRangeLow;
  final String salaryRangeHigh;

  MarketOverview({
    required this.currentDemand,
    required this.growthProjection,
    required this.salaryRangeLow,
    required this.salaryRangeHigh,
  });
}

class CareerSkill {
  final String name;
  final SkillType type; // Technical or Soft
  final SkillLevel level; // Basic, Intermediate, Advanced, Expert
  final bool isCertificationNeeded;
  final String? certificationName;

  CareerSkill({
    required this.name,
    required this.type,
    required this.level,
    required this.isCertificationNeeded,
    this.certificationName,
  });
}

enum SkillType {
  technical,
  soft,
}

enum SkillLevel {
  basic,
  intermediate,
  advanced,
  expert,
}

class EducationPathway {
  final List<EducationStep> steps;
  final List<String> alternativePaths;

  EducationPathway({
    required this.steps,
    required this.alternativePaths,
  });
}

class EducationStep {
  final String title;
  final String description;
  final List<String> recommendations;
  final int durationInYears;
  final bool isRequired;

  EducationStep({
    required this.title,
    required this.description,
    required this.recommendations,
    required this.durationInYears,
    required this.isRequired,
  });
}

class CareerPosition {
  final String title;
  final String description;
  final String typicalSalaryRange;
  final List<String> responsibilities;
  final int yearsOfExperienceNeeded;

  CareerPosition({
    required this.title,
    required this.description,
    required this.typicalSalaryRange,
    required this.responsibilities,
    required this.yearsOfExperienceNeeded,
  });
}

class SuccessStory {
  final String name;
  final String role;
  final String company;
  final String story;
  final String? imagePath;

  SuccessStory({
    required this.name,
    required this.role,
    required this.company,
    required this.story,
    this.imagePath,
  });
}
