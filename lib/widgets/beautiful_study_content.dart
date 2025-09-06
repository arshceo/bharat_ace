// lib/widgets/beautiful_study_content.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import '../core/theme/app_theme.dart';
import '../core/models/study_task_model.dart';
import 'professional_card.dart' as widgets;

// Study Content Provider
final studyContentProvider = StateNotifierProvider.family<StudyContentNotifier,
    AsyncValue<String>, StudyTask>((ref, task) {
  return StudyContentNotifier(task);
});

class StudyContentNotifier extends StateNotifier<AsyncValue<String>> {
  final StudyTask task;

  StudyContentNotifier(this.task) : super(const AsyncValue.data(''));

  Future<void> generateStudyContent() async {
    state = const AsyncValue.loading();
    try {
      final model = ai.GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: dotenv.env['GEMINI_API']?.replaceAll('"', '') ?? '',
      );

      // Subject-specific prompt generation for optimal memory techniques
      String getSubjectSpecificPrompt(
          String subject, String topic, String chapter) {
        final subjectLower = subject.toLowerCase();

        String memoryTechniques = '';
        String examTips = '';
        String specificApproach = '';

        if (subjectLower.contains('history')) {
          memoryTechniques = '''
          - 📚 STORY-MAKING: Create compelling narratives connecting events
          - 🎭 CHARACTER MAPPING: Remember personalities and their roles
          - ⏰ TIMELINE SONGS: Musical chronology for dates and sequences
          - 🗺️ VISUAL MAPS: Mental geography for battles, movements, kingdoms
          - 🎪 DRAMATIC RE-ENACTMENT: Act out historical scenes mentally
          - 🔗 CAUSE-EFFECT CHAINS: Link events in logical story sequences
          ''';
          examTips = '''
          - Always draw timelines and maps in answers
          - Use specific dates, places, and names for credibility
          - Structure answers: Introduction → Main events → Impact → Conclusion
          - Include multiple perspectives when discussing events
          - Connect past events to present-day relevance
          ''';
          specificApproach =
              'Focus on storytelling, chronological connections, and visual memory techniques for historical events.';
        } else if (subjectLower.contains('science') ||
            subjectLower.contains('physics') ||
            subjectLower.contains('chemistry') ||
            subjectLower.contains('biology')) {
          memoryTechniques = '''
          - 🔬 DIAGRAM DRAWING: Visualize processes and structures
          - 🧪 EXPERIMENT STORIES: Remember procedures through mini-narratives
          - 📝 FORMULA RHYMES: Musical memory for equations and constants
          - 🎨 COLOR CODING: Different colors for different elements/processes
          - 🏠 LAB MEMORY PALACE: Place concepts in familiar laboratory settings
          - 🔄 PROCESS FLOW CHARTS: Step-by-step visual sequences
          ''';
          examTips = '''
          - Always draw clear, labeled diagrams
          - Show all working steps in calculations
          - Use correct scientific terminology and units
          - Include real-world applications and examples
          - Explain the "why" behind processes, not just the "what"
          ''';
          specificApproach =
              'Emphasize visual diagrams, process understanding, and scientific method application.';
        } else if (subjectLower.contains('math') ||
            subjectLower.contains('mathematics')) {
          memoryTechniques = '''
          - 🔢 PATTERN RECOGNITION: Find visual and numerical patterns
          - 🎵 FORMULA SONGS: Musical memory for equations and theorems
          - 🏗️ STEP-BY-STEP BUILDINGS: Construct solutions like building blocks
          - 🎨 GEOMETRIC VISUALIZATION: Draw and imagine shapes and graphs
          - 🔄 PRACTICE LOOPS: Repetitive pattern solving for muscle memory
          - 🧩 PUZZLE CONNECTIONS: Link different concepts as puzzle pieces
          ''';
          examTips = '''
          - Show all calculation steps clearly
          - Draw graphs and diagrams wherever applicable
          - Check answers by substitution or alternative methods
          - Use proper mathematical notation and symbols
          - Explain reasoning for each major step taken
          ''';
          specificApproach =
              'Focus on logical step-by-step processes, pattern recognition, and visual problem-solving.';
        } else if (subjectLower.contains('language') ||
            subjectLower.contains('english') ||
            subjectLower.contains('literature')) {
          memoryTechniques = '''
          - 📖 CHARACTER PERSONALITY MAPS: Deep character analysis and connections
          - 🎭 SCENE VISUALIZATION: Imagine and act out literary scenes
          - 🎨 THEME COLOR CODING: Associate themes with specific colors
          - 📝 QUOTE COLLECTIONS: Memorable lines with context
          - 🔗 LITERARY DEVICE CHAINS: Connect techniques across different works
          - 🏠 STORY MEMORY PALACE: Place plot elements in familiar settings
          ''';
          examTips = '''
          - Support arguments with specific textual evidence and quotes
          - Analyze literary devices and their effects on meaning
          - Structure essays with clear introduction, body, and conclusion
          - Show understanding of context (historical, social, cultural)
          - Use sophisticated vocabulary and varied sentence structures
          ''';
          specificApproach =
              'Emphasize textual analysis, character development, and thematic understanding.';
        } else if (subjectLower.contains('geography')) {
          memoryTechniques = '''
          - 🗺️ MENTAL MAPPING: Create detailed mental maps of regions
          - 🌍 LANDMARK ASSOCIATIONS: Connect features with memorable landmarks
          - 📊 DATA VISUALIZATION: Transform statistics into visual stories
          - 🎵 LOCATION SONGS: Musical memory for places and coordinates
          - 🏔️ FEATURE STORYTELLING: Create narratives around geographical features
          - 📸 VIRTUAL JOURNEYS: Imagine traveling through different regions
          ''';
          examTips = '''
          - Always include maps, diagrams, and sketch illustrations
          - Use specific data, statistics, and case study examples
          - Show relationships between human and physical geography
          - Discuss both local and global perspectives
          - Include current events and contemporary relevance
          ''';
          specificApproach =
              'Focus on spatial awareness, data interpretation, and human-environment relationships.';
        } else {
          memoryTechniques = '''
          - 🧠 CONCEPT MAPPING: Visual connections between ideas
          - 📝 ACRONYM CREATION: Memorable abbreviations for key points
          - 🎨 VISUAL ASSOCIATIONS: Link concepts to memorable images
          - 🔄 REPETITION PATTERNS: Structured review and practice
          - 🏠 MEMORY PALACE: Place information in familiar locations
          - 🎵 RHYTHMIC LEARNING: Use rhythm and rhyme for memorization
          ''';
          examTips = '''
          - Structure answers with clear introduction, body, and conclusion
          - Use specific examples and evidence to support points
          - Show understanding through explanation and analysis
          - Connect concepts to real-world applications
          - Use appropriate subject-specific terminology
          ''';
          specificApproach =
              'Focus on conceptual understanding, critical thinking, and application of knowledge.';
        }

        return '''
You are an expert educational content creator and memory specialist specializing in ${task.subject}. Create absolutely stunning, mobile-friendly, and comprehensive study content for "${task.topic}" from the chapter "${task.chapter}".

$specificApproach

CRITICAL REQUIREMENTS:
- Return ONLY beautiful, colorful HTML content with NO CSS animations, NO @keyframes, NO <style> tags
- Use ONLY inline styles with bright, vibrant, eye-catching colors
- NO JSON wrapper, NO markdown formatting, NO code blocks
- Make content 100% mobile-friendly and fully visible
- Use beautiful gradients and color combinations
- Include ALL information with NO placeholders like "[Create examples]" - generate actual complete content
- Use emojis, icons, and visual elements for engagement

BRIGHT COLOR PALETTE TO USE:
- Vibrant blues: #667eea, #764ba2, #4facfe, #00f2fe
- Energetic pinks: #f093fb, #f5576c, #fa709a, #fee140
- Fresh greens: #a8edea, #fed6e3, #84fab0, #8fd3f4
- Warm oranges: #ffecd2, #fcb69f, #ff9a9e, #fecfef

SUBJECT-SPECIFIC MEMORY TECHNIQUES for ${task.subject}:
$memoryTechniques

EXAM SUCCESS STRATEGIES for ${task.subject}:
$examTips

Create mobile-friendly content structure with BRIGHT, COLORFUL, and BEAUTIFUL design:

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 25px; border-radius: 20px; color: white; box-shadow: 0 12px 40px rgba(0,0,0,0.3); margin: 15px 0; max-width: 100%; overflow: hidden; border: 3px solid rgba(255,255,255,0.2);">
  <h1 style="margin: 0 0 20px 0; text-align: center; font-size: 28px; font-weight: bold; text-shadow: 3px 3px 6px rgba(0,0,0,0.4); line-height: 1.3; background: linear-gradient(45deg, #ffd700, #ffb347); -webkit-background-clip: text; color: transparent; font-family: 'Arial Black', Arial, sans-serif;">
    📚 ${task.topic}
  </h1>
  <p style="margin: 0; font-size: 18px; line-height: 1.6; text-align: center; opacity: 0.95; background: rgba(255,255,255,0.15); padding: 10px; border-radius: 10px;">
    <strong>Chapter:</strong> ${task.chapter} | <strong>Subject:</strong> ${task.subject}
  </p>
  <div style="margin-top: 20px; text-align: center; padding: 15px; background: linear-gradient(45deg, #ff6b6b, #ffa726); border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
    <span style="font-size: 16px; font-weight: bold; color: white; text-shadow: 1px 1px 3px rgba(0,0,0,0.5);">🎯 Master with Memory Techniques!</span>
  </div>
</div>

<div style="background: linear-gradient(135deg, #ff6b6b 0%, #ffa726 100%); padding: 25px; border-radius: 20px; color: white; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.2);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; text-shadow: 2px 2px 4px rgba(0,0,0,0.4); flex-wrap: wrap; background: linear-gradient(45deg, #fff, #ffe0b3); -webkit-background-clip: text; color: transparent; font-weight: bold;">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.2); padding: 8px; border-radius: 50%; color: white;">🎯</span>
    Key Concepts & Memory Tricks
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.2), rgba(255,255,255,0.1)); padding: 20px; border-radius: 15px; border: 2px solid rgba(255,255,255,0.3); box-shadow: inset 0 2px 10px rgba(0,0,0,0.1);">
    [Create 4-5 key concepts with subject-specific memory techniques, each with:
    - Clear explanation suitable for mobile reading with bright colors
    - 🧠 MEMORY TRICK section using techniques specific to ${task.subject}
    - 🎨 Visual examples with colorful backgrounds and borders
    - ⚡ Quick recall tips optimized for mobile learning with vibrant styling]
  </div>
</div>

<div style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); padding: 25px; border-radius: 20px; color: white; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.2);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; flex-wrap: wrap; text-shadow: 2px 2px 4px rgba(0,0,0,0.4);">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.2); padding: 8px; border-radius: 50%;">💡</span>
    Smart Definitions & Memory Hooks
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.2), rgba(255,255,255,0.1)); padding: 20px; border-radius: 15px; border: 2px solid rgba(255,255,255,0.3);">
    [Create definition cards optimized for ${task.subject}, each with:
    - Main definition in simple, mobile-friendly terms with colorful backgrounds
    - 🎭 Subject-specific memory technique with bright visual elements
    - 🔗 Connection to familiar concepts using vibrant colors
    - 📱 Modern examples with eye-catching styling]
  </div>
</div>

<div style="background: linear-gradient(135deg, #fa709a 0%, #fee140 100%); padding: 25px; border-radius: 20px; color: #2d3748; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.4);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; text-shadow: 1px 1px 3px rgba(255,255,255,0.7); flex-wrap: wrap; font-weight: bold;">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.3); padding: 8px; border-radius: 50%; color: #2d3748;">🔍</span>
    Real-World Applications
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.4), rgba(255,255,255,0.2)); padding: 20px; border-radius: 15px; border: 3px dashed rgba(255,255,255,0.8); box-shadow: inset 0 2px 10px rgba(0,0,0,0.1);">
    [Create engaging real-world examples relevant to ${task.subject}:
    - 🌟 Current applications with bright, colorful presentation
    - 📱 Technology connections using vibrant styling
    - 🎮 Relatable analogies with fun colors and gradients
    - 🚀 Future opportunities with eye-catching design]
  </div>
</div>

<div style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); padding: 25px; border-radius: 20px; color: #2d3748; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.4);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; flex-wrap: wrap; font-weight: bold; text-shadow: 1px 1px 3px rgba(255,255,255,0.7);">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.3); padding: 8px; border-radius: 50%;">⚡</span>
    ${task.subject} Memory Mastery
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.5), rgba(255,255,255,0.3)); padding: 20px; border-radius: 15px; border: 2px solid rgba(255,255,255,0.6);">
    [Use the BEST memory techniques for ${task.subject}:
    $memoryTechniques
    - Create specific examples for ${task.topic} with colorful visual aids
    - Make techniques mobile-learning friendly with bright styling
    - Include quick practice exercises with vibrant design elements]
  </div>
</div>

<div style="background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); padding: 25px; border-radius: 20px; color: #2d3748; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.4);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; flex-wrap: wrap; font-weight: bold;">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.3); padding: 8px; border-radius: 50%;">🎪</span>
    Interactive Practice
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.5), rgba(255,255,255,0.3)); padding: 20px; border-radius: 15px; border: 2px solid rgba(255,255,255,0.6);">
    [Create mobile-friendly interactive elements:
    - 🎯 Quick self-test questions for ${task.topic} with colorful formatting
    - 🎲 Touch-friendly practice exercises with bright visual appeal
    - 🧩 Visual challenges with stunning color combinations
    - 📝 Drawing/note-taking exercises with vibrant styling]
  </div>
</div>

<div style="background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%); padding: 25px; border-radius: 20px; color: #2d3748; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 4px solid #ff6b9d;">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; flex-wrap: wrap; font-weight: bold; color: #d63384;">
    <span style="margin-right: 15px; font-size: 32px; background: linear-gradient(45deg, #ff6b9d, #c44569); padding: 10px; border-radius: 50%; color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">🏆</span>
    EXAM SUCCESS SECRETS
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.6), rgba(255,255,255,0.4)); padding: 20px; border-radius: 15px; border: 3px solid rgba(214,51,132,0.3); box-shadow: inset 0 2px 10px rgba(0,0,0,0.1);">
    <h3 style="margin: 0 0 15px 0; color: #c44569; font-size: 20px; background: linear-gradient(45deg, #ff6b9d, #c44569); padding: 10px; border-radius: 10px; color: white; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">📝 Most Important Questions for ${task.topic}:</h3>
    [List 5-7 crucial exam questions with bright, organized formatting:
    - Exact question types with colorful highlighting
    - Point values with vibrant styling
    - Time management tips with visual emphasis]
    
    <h3 style="margin: 20px 0 15px 0; color: white; font-size: 20px; background: linear-gradient(45deg, #4facfe, #00f2fe); padding: 10px; border-radius: 10px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">💯 How to Answer for FULL MARKS:</h3>
    [Provide detailed answering strategies with colorful presentation:
    $examTips
    - Step-by-step answer structure with vibrant formatting
    - Key words and phrases highlighted in bright colors
    - Common mistakes in red warning boxes]
    
    <h3 style="margin: 20px 0 15px 0; color: white; font-size: 20px; background: linear-gradient(45deg, #ffa726, #ff6b6b); padding: 10px; border-radius: 10px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">🎯 ${task.subject} Exam Pro Tips:</h3>
    [Subject-specific exam strategies with stunning visual design:
    - Time allocation strategies with colorful charts and graphics
    - Difficult question handling with bright visual guides
    - Last-minute revision techniques with eye-catching formatting
    - Examiner expectations with highlighted key points]
  </div>
</div>

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 25px; border-radius: 20px; color: white; margin: 20px 0; box-shadow: 0 12px 40px rgba(0,0,0,0.3); max-width: 100%; border: 3px solid rgba(255,255,255,0.2);">
  <h2 style="margin: 0 0 20px 0; display: flex; align-items: center; font-size: 24px; flex-wrap: wrap; font-weight: bold;">
    <span style="margin-right: 15px; font-size: 32px; background: rgba(255,255,255,0.2); padding: 8px; border-radius: 50%;">📋</span>
    Master Summary & Quick Revision
  </h2>
  <div style="background: linear-gradient(45deg, rgba(255,255,255,0.2), rgba(255,255,255,0.1)); padding: 20px; border-radius: 15px; border: 2px solid rgba(255,255,255,0.3);">
    [Create the ultimate mobile-friendly summary with stunning visuals:
    - 🗺️ Visual concept map with colorful connections and bright styling
    - 🎯 Top 5 points with vibrant highlighting and gradients
    - 🧠 Final master memory technique with colorful visual elements
    - ⭐ One-sentence summaries with bright, eye-catching formatting
    - 📱 Quick facts with colorful boxes and visual appeal]
  </div>
</div>

VISUAL DESIGN REQUIREMENTS:
- Use BRIGHT, VIBRANT colors throughout (avoid dull or muted tones)
- Apply multiple gradient backgrounds for visual appeal
- Add colorful borders, shadows, and visual elements
- Use different font weights and sizes for hierarchy
- Include emoji icons with colorful background circles
- Apply text shadows and visual effects for depth
- Use contrasting colors for maximum readability
- Create visually distinct sections with varied color schemes

MOBILE-FRIENDLY REQUIREMENTS:
- All text readable on small screens (16px+ font size)
- No fixed widths, use max-width: 100%
- Proper line-height (1.4-1.6) for mobile reading
- Touch-friendly interactive elements
- Responsive padding and margins (20-25px)
- NO CSS animations or @keyframes (causes flutter_html errors)
- Use only inline styles with gradients and colors
- Flex-wrap for multi-line headings on small screens
- Content optimized for portrait mobile viewing

CONTENT COMPLETENESS:
- Provide FULL, DETAILED content for each section
- Don't use placeholder text - fill everything with actual educational content
- Make content comprehensive and complete
- Include specific examples, facts, and detailed explanations
- Ensure all sections have substantial, helpful information

Return ONLY the beautiful, colorful, mobile-friendly HTML content above, properly filled with subject-specific educational content and POWERFUL MEMORY TECHNIQUES for ${task.topic}, plus comprehensive EXAM SUCCESS strategies.
''';
      }

      final prompt = getSubjectSpecificPrompt(
          task.subject, task.topic ?? '', task.chapter ?? '');

      final content = [ai.Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      state = AsyncValue.data(responseText);
    } catch (e) {
      print('Error generating study content: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Beautiful Study Content Widget
class BeautifulStudyContent extends ConsumerStatefulWidget {
  final StudyTask task;
  final VoidCallback? onContentCompleted;

  const BeautifulStudyContent({
    super.key,
    required this.task,
    this.onContentCompleted,
  });

  @override
  ConsumerState<BeautifulStudyContent> createState() =>
      _BeautifulStudyContentState();
}

class _BeautifulStudyContentState extends ConsumerState<BeautifulStudyContent>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(studyContentProvider(widget.task).notifier)
          .generateStudyContent();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(studyContentProvider(widget.task));

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📚 Study: ${widget.task.subject}',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            Text(
              widget.task.topic ?? 'Study Topic',
              style: AppTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.gray600,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.white,
        elevation: 2,
        shadowColor: AppTheme.gray900.withOpacity(0.1),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spaceMD),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMD,
                  vertical: AppTheme.spaceXS,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  'AI Generated',
                  style: AppTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: contentState.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                '🎨 Creating Beautiful Content...',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'AI is crafting stunning visual content for ${widget.task.topic ?? "your topic"}',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(),
        data: (htmlContent) {
          if (htmlContent.isEmpty) {
            return _buildErrorState();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Html(
                        data: htmlContent,
                        shrinkWrap: true,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontFamily: 'Inter',
                          ),
                          "div": Style(
                            margin: Margins.zero,
                          ),
                          "h1": Style(
                            fontSize: FontSize(28),
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                            margin: Margins.only(bottom: 25),
                            color: Colors.white,
                          ),
                          "h2": Style(
                            fontSize: FontSize(24),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(bottom: 20),
                            color: Colors.white,
                          ),
                          "h3": Style(
                            fontSize: FontSize(20),
                            fontWeight: FontWeight.w600,
                            margin: Margins.only(bottom: 15),
                          ),
                          "p": Style(
                            fontSize: FontSize(16),
                            lineHeight: LineHeight(1.6),
                            margin: Margins.only(bottom: 10),
                          ),
                          "strong": Style(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a1a1a),
                          ),
                          "em": Style(
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF4a5568),
                          ),
                          "ul": Style(
                            margin: Margins.only(left: 20, bottom: 10),
                            listStyleType: ListStyleType.disc,
                          ),
                          "ol": Style(
                            margin: Margins.only(left: 20, bottom: 10),
                            listStyleType: ListStyleType.decimal,
                          ),
                          "li": Style(
                            margin: Margins.only(bottom: 8),
                            fontSize: FontSize(15),
                            lineHeight: LineHeight(1.5),
                            padding: HtmlPaddings.only(bottom: 5),
                            listStyleType: ListStyleType.disc,
                          ),
                          "span": Style(
                            fontSize: FontSize(16),
                          ),
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLG),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gray900.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onContentCompleted,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceLG),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ).copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spaceLG),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.quiz_outlined,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: AppTheme.spaceMD),
                                Text(
                                  'Continue to Quiz',
                                  style:
                                      AppTheme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: widgets.ProfessionalCard(
          color: AppTheme.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Icon(
                    Icons.palette_outlined,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text(
                'Content Generation Failed',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Our AI couldn\'t create the beautiful content right now. This might be due to network issues.',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gray700,
                        side: BorderSide(color: AppTheme.gray300),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(studyContentProvider(widget.task).notifier)
                            .generateStudyContent();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
