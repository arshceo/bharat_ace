import 'package:bharat_ace/core/models/career_models.dart';

class CareerDataService {
  static List<Career> getAllCareers() {
    return [
      Career(
        id: 'software-engineer',
        title: 'Software Engineer',
        shortDescription: 'Design and build computer systems and applications',
        longDescription:
            'Software engineers apply engineering principles to build software solutions. They develop applications, systems, and software for various purposes, working with programming languages, frameworks, and tools.',
        iconPath: 'assets/careers/software_engineer.png',
        category: 'Technology',
        details: CareerDetails(
          marketOverview: MarketOverview(
            currentDemand: 'Very High',
            growthProjection: '22% (much faster than average)',
            salaryRangeLow: '₹5,00,000',
            salaryRangeHigh: '₹25,00,000',
          ),
          requiredSkills: [
            CareerSkill(
              name: 'Programming Languages (Java, Python, etc.)',
              type: SkillType.technical,
              level: SkillLevel.advanced,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Data Structures & Algorithms',
              type: SkillType.technical,
              level: SkillLevel.advanced,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Problem Solving',
              type: SkillType.soft,
              level: SkillLevel.expert,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Database Management',
              type: SkillType.technical,
              level: SkillLevel.intermediate,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'AWS Certification',
              type: SkillType.technical,
              level: SkillLevel.intermediate,
              isCertificationNeeded: true,
              certificationName: 'AWS Certified Developer',
            ),
          ],
          educationPathway: EducationPathway(
            steps: [
              EducationStep(
                title: 'High School',
                description:
                    'Focus on mathematics, physics, and computer science',
                recommendations: [
                  'AP Computer Science',
                  'Mathematics with focus on algebra and calculus',
                  'Participate in coding competitions'
                ],
                durationInYears: 2,
                isRequired: true,
              ),
              EducationStep(
                title: 'Bachelor\'s Degree',
                description:
                    'Computer Science, Software Engineering or related field',
                recommendations: [
                  'B.Tech in Computer Science',
                  'BSc in Computer Science',
                  'BCA (Bachelor of Computer Applications)'
                ],
                durationInYears: 4,
                isRequired: true,
              ),
              EducationStep(
                title: 'Master\'s Degree (Optional)',
                description:
                    'Advanced specialization in specific areas like AI, ML, Cybersecurity',
                recommendations: [
                  'M.Tech in Computer Science',
                  'MSc in Computer Science',
                  'MCA (Master of Computer Applications)'
                ],
                durationInYears: 2,
                isRequired: false,
              ),
            ],
            alternativePaths: [
              'Coding Bootcamps (3-6 months intensive training)',
              'Self-learning through online platforms (Coursera, Udemy, etc.)',
              'Open-source contributions and building a portfolio',
            ],
          ),
          careerProgression: [
            CareerPosition(
              title: 'Junior Software Engineer',
              description:
                  'Entry-level position focusing on coding and basic problem-solving',
              typicalSalaryRange: '₹3,00,000 - ₹8,00,000',
              responsibilities: [
                'Writing and debugging code',
                'Participating in code reviews',
                'Working under senior engineers',
              ],
              yearsOfExperienceNeeded: 0,
            ),
            CareerPosition(
              title: 'Software Engineer',
              description:
                  'Mid-level position with more autonomy and responsibility',
              typicalSalaryRange: '₹8,00,000 - ₹15,00,000',
              responsibilities: [
                'Designing and implementing features',
                'Collaborating with other teams',
                'Mentoring junior engineers',
              ],
              yearsOfExperienceNeeded: 2,
            ),
            CareerPosition(
              title: 'Senior Software Engineer',
              description:
                  'Leading technical initiatives and making architectural decisions',
              typicalSalaryRange: '₹15,00,000 - ₹30,00,000',
              responsibilities: [
                'Architecting complex systems',
                'Leading project teams',
                'Technical decision making',
              ],
              yearsOfExperienceNeeded: 5,
            ),
            CareerPosition(
              title: 'Technical Lead / Engineering Manager',
              description:
                  'Managing teams while maintaining technical expertise',
              typicalSalaryRange: '₹25,00,000 - ₹50,00,000',
              responsibilities: [
                'Team management',
                'Project planning',
                'Technical guidance',
              ],
              yearsOfExperienceNeeded: 8,
            ),
          ],
          industryInsights: [
            'Top companies include Google, Microsoft, Amazon, and numerous startups',
            'Remote work opportunities are abundant in this field',
            'Continuous learning is essential as technologies evolve rapidly',
            'Strong growth expected in AI, cloud computing, and cybersecurity',
          ],
          successStories: [
            SuccessStory(
              name: 'Sundar Pichai',
              role: 'CEO',
              company: 'Google',
              story:
                  'Started as a materials engineer and product manager before rising through the ranks at Google to become CEO.',
              imagePath: 'assets/careers/success_stories/sundar_pichai.jpg',
            ),
            SuccessStory(
              name: 'Satya Nadella',
              role: 'CEO',
              company: 'Microsoft',
              story:
                  'Joined Microsoft in 1992 and worked his way up from the engineering team to CEO, transforming the company\'s culture and focus.',
              imagePath: 'assets/careers/success_stories/satya_nadella.jpg',
            ),
          ],
        ),
      ),
      Career(
        id: 'doctor',
        title: 'Doctor',
        shortDescription: 'Diagnose and treat health conditions',
        longDescription:
            'Doctors are healthcare professionals who diagnose, treat, and prevent illnesses, diseases, and injuries. They work in various specialties to provide medical care and improve patient health.',
        iconPath: 'assets/careers/doctor.png',
        category: 'Healthcare',
        details: CareerDetails(
          marketOverview: MarketOverview(
            currentDemand: 'High',
            growthProjection: '7% (faster than average)',
            salaryRangeLow: '₹8,00,000',
            salaryRangeHigh: '₹40,00,000+',
          ),
          requiredSkills: [
            CareerSkill(
              name: 'Clinical Knowledge',
              type: SkillType.technical,
              level: SkillLevel.expert,
              isCertificationNeeded: true,
              certificationName: 'Medical License',
            ),
            CareerSkill(
              name: 'Diagnostic Reasoning',
              type: SkillType.technical,
              level: SkillLevel.expert,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Communication',
              type: SkillType.soft,
              level: SkillLevel.expert,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Empathy',
              type: SkillType.soft,
              level: SkillLevel.advanced,
              isCertificationNeeded: false,
            ),
          ],
          educationPathway: EducationPathway(
            steps: [
              EducationStep(
                title: 'High School',
                description:
                    'Focus on biology, chemistry, physics, and mathematics',
                recommendations: [
                  'Biology (Advanced level)',
                  'Chemistry',
                  'Physics',
                  'Mathematics'
                ],
                durationInYears: 2,
                isRequired: true,
              ),
              EducationStep(
                title: 'MBBS (Bachelor of Medicine, Bachelor of Surgery)',
                description:
                    'Undergraduate medical degree with clinical training',
                recommendations: [
                  'NEET preparation',
                  'Strong foundation in anatomy, physiology, biochemistry',
                  'Clinical rotations'
                ],
                durationInYears: 6,
                isRequired: true,
              ),
              EducationStep(
                title: 'Internship',
                description:
                    'Mandatory rotational internship in various departments',
                recommendations: [
                  'Gain experience in all major specialties',
                  'Develop practical clinical skills',
                ],
                durationInYears: 1,
                isRequired: true,
              ),
              EducationStep(
                title: 'Post-Graduation (MD/MS)',
                description: 'Specialization in chosen field',
                recommendations: [
                  'NEET PG preparation',
                  'Choose specialty based on interest and aptitude',
                ],
                durationInYears: 3,
                isRequired: false,
              ),
              EducationStep(
                title: 'Super-specialization (DM/MCh)',
                description: 'Further specialization in subspecialties',
                recommendations: [
                  'For advanced specialized practice',
                ],
                durationInYears: 3,
                isRequired: false,
              ),
            ],
            alternativePaths: [
              'AYUSH courses (BAMS, BHMS, BUMS, etc.)',
              'Research-focused medical careers (starting with MD-PhD)',
              'Public health specialization (MPH after MBBS)',
            ],
          ),
          careerProgression: [
            CareerPosition(
              title: 'Junior Resident',
              description: 'Working under supervision in hospitals after MBBS',
              typicalSalaryRange: '₹6,00,000 - ₹10,00,000',
              responsibilities: [
                'Patient care under supervision',
                'Assisting in procedures',
                'Documentation and record-keeping',
              ],
              yearsOfExperienceNeeded: 0,
            ),
            CareerPosition(
              title: 'Medical Officer',
              description:
                  'Independent practice with general medical responsibilities',
              typicalSalaryRange: '₹8,00,000 - ₹15,00,000',
              responsibilities: [
                'Patient diagnosis and treatment',
                'Preventive care',
                'Referrals to specialists',
              ],
              yearsOfExperienceNeeded: 1,
            ),
            CareerPosition(
              title: 'Specialist',
              description:
                  'Expert in a specific medical field after post-graduation',
              typicalSalaryRange: '₹15,00,000 - ₹30,00,000',
              responsibilities: [
                'Specialized diagnosis and treatment',
                'Complex case management',
                'Teaching junior doctors',
              ],
              yearsOfExperienceNeeded: 5,
            ),
            CareerPosition(
              title: 'Senior Consultant',
              description: 'Leading medical professional in specialty',
              typicalSalaryRange: '₹30,00,000 - ₹60,00,000+',
              responsibilities: [
                'Leading medical teams',
                'Complex and critical cases',
                'Department management',
                'Research and publication',
              ],
              yearsOfExperienceNeeded: 10,
            ),
          ],
          industryInsights: [
            'Growing opportunities in both public and private healthcare sectors',
            'Increasing demand due to aging population and healthcare awareness',
            'Technological integration (telemedicine, AI in diagnostics) changing practice',
            'Options to work in hospitals, private practice, research, or academia',
          ],
          successStories: [
            SuccessStory(
              name: 'Dr. Devi Shetty',
              role: 'Cardiac Surgeon & Founder',
              company: 'Narayana Health',
              story:
                  'Pioneered affordable cardiac care in India, performing over 15,000 heart surgeries and building a hospital chain that provides quality healthcare at reduced costs.',
              imagePath: 'assets/careers/success_stories/devi_shetty.jpg',
            ),
            SuccessStory(
              name: 'Dr. Soumya Swaminathan',
              role: 'Chief Scientist',
              company: 'World Health Organization',
              story:
                  'From practicing pediatrician to leading global health research, became the first Chief Scientist at WHO, guiding scientific research initiatives worldwide.',
              imagePath:
                  'assets/careers/success_stories/soumya_swaminathan.jpg',
            ),
          ],
        ),
      ),
      // More careers can be added here
      Career(
        id: 'digital-content-creator',
        title: 'Digital Content Creator',
        shortDescription: 'Create engaging online content across platforms',
        longDescription:
            'Digital content creators produce various forms of media for online platforms, including videos, blogs, podcasts, and social media content. They combine creativity with strategic thinking to engage audiences.',
        iconPath: 'assets/careers/content_creator.png',
        category: 'Media & Entertainment',
        details: CareerDetails(
          marketOverview: MarketOverview(
            currentDemand: 'High',
            growthProjection: '18% (much faster than average)',
            salaryRangeLow: 'Variable',
            salaryRangeHigh: 'Unlimited (based on audience and monetization)',
          ),
          requiredSkills: [
            CareerSkill(
              name: 'Content Creation',
              type: SkillType.technical,
              level: SkillLevel.advanced,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Video Editing',
              type: SkillType.technical,
              level: SkillLevel.intermediate,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Digital Marketing',
              type: SkillType.technical,
              level: SkillLevel.intermediate,
              isCertificationNeeded: false,
            ),
            CareerSkill(
              name: 'Audience Engagement',
              type: SkillType.soft,
              level: SkillLevel.advanced,
              isCertificationNeeded: false,
            ),
          ],
          educationPathway: EducationPathway(
            steps: [
              EducationStep(
                title: 'High School',
                description: 'Focus on communication, arts, media studies',
                recommendations: [
                  'English/Communication',
                  'Media Studies',
                  'Creative Arts',
                ],
                durationInYears: 2,
                isRequired: true,
              ),
              EducationStep(
                title: 'Bachelor\'s Degree (Optional)',
                description: 'Mass Communication, Journalism, Digital Media',
                recommendations: [
                  'BA in Mass Communication',
                  'BA in Journalism',
                  'BFA in Digital Arts',
                ],
                durationInYears: 3,
                isRequired: false,
              ),
            ],
            alternativePaths: [
              'Self-learning through online courses (YouTube, Skillshare, etc.)',
              'Mentorship from established creators',
              'Starting small and building a portfolio through practice',
              'Digital marketing certifications',
            ],
          ),
          careerProgression: [
            CareerPosition(
              title: 'Beginner Creator',
              description: 'Building initial audience and content style',
              typicalSalaryRange: 'Variable (Often minimal)',
              responsibilities: [
                'Creating consistent content',
                'Learning platform algorithms',
                'Building initial audience',
              ],
              yearsOfExperienceNeeded: 0,
            ),
            CareerPosition(
              title: 'Established Creator',
              description: 'Monetizing content with growing audience',
              typicalSalaryRange: '₹2,00,000 - ₹10,00,000',
              responsibilities: [
                'Regular content schedule',
                'Brand partnerships',
                'Community management',
              ],
              yearsOfExperienceNeeded: 1,
            ),
            CareerPosition(
              title: 'Professional Creator',
              description: 'Full-time creator with multiple revenue streams',
              typicalSalaryRange: '₹10,00,000 - ₹50,00,000+',
              responsibilities: [
                'Content strategy',
                'Team management',
                'Multiple revenue streams',
              ],
              yearsOfExperienceNeeded: 3,
            ),
            CareerPosition(
              title: 'Influencer/Content Entrepreneur',
              description: 'Building a brand and business around content',
              typicalSalaryRange: '₹50,00,000+ (Potentially much higher)',
              responsibilities: [
                'Content business management',
                'Product development',
                'Strategic partnerships',
              ],
              yearsOfExperienceNeeded: 5,
            ),
          ],
          industryInsights: [
            'Rapidly evolving landscape with new platforms emerging regularly',
            'Income typically comes from multiple sources (ads, sponsorships, products)',
            'Requires constant adaptation to algorithm changes',
            'Highly competitive but with unlimited growth potential',
          ],
          successStories: [
            SuccessStory(
              name: 'Bhuvan Bam',
              role: 'Content Creator',
              company: 'BB Ki Vines',
              story:
                  'Started creating comedy videos on YouTube and became one of India\'s biggest digital stars with millions of followers and successful brand ventures.',
              imagePath: 'assets/careers/success_stories/bhuvan_bam.jpg',
            ),
            SuccessStory(
              name: 'Ranveer Allahbadia',
              role: 'Content Creator & Entrepreneur',
              company: 'BeerBiceps',
              story:
                  'Built a multi-channel content empire focused on self-improvement, with podcasts, YouTube channels, and a talent management company.',
              imagePath:
                  'assets/careers/success_stories/ranveer_allahbadia.jpg',
            ),
          ],
        ),
      ),
    ];
  }

  static List<String> getCareerCategories() {
    return [
      'Technology',
      'Healthcare',
      'Business',
      'Arts & Design',
      'Education',
      'Science & Research',
      'Media & Entertainment',
      'Engineering',
      'Public Service',
      'Sports & Fitness',
    ];
  }

  static List<Career> getCareersByCategory(String category) {
    return getAllCareers()
        .where((career) => career.category == category)
        .toList();
  }

  static Career? getCareerById(String id) {
    try {
      return getAllCareers().firstWhere((career) => career.id == id);
    } catch (e) {
      return null;
    }
  }
}
