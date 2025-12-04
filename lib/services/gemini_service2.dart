// lib/services/gemini_service.dart - OPTIMIZED VERSION
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_wise/config/gemini_config.dart';
import '../model/ai_match_model.dart';
import 'local_data_source.dart';

<<<<<<<< HEAD:lib/services/gemini_service.dart
class GeminiService {
  static final GeminiService instance = GeminiService._init();
  GeminiService._init();
========
class AiService {
  final String apiKey = 'AIzaSyDOmbENlNrvNacS9fCbUqD9PSyEhilP9Ss';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
>>>>>>>> Tay:lib/services/gemini_service2.dart

  static const int _maxRetries = 2;
  static const Duration _timeout = Duration(seconds: 90);

  /// Generate AI education match recommendations with retry logic
  Future<AIMatchResponse> generateEducationMatch(AIMatchRequest request) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount <= _maxRetries) {
      try {
        debugPrint('🤖 Gemini API request (attempt ${retryCount + 1}/${_maxRetries + 1})...');

        final prompt = await _buildPrompt(request);
        final response = await _callGeminiAPI(prompt);

        debugPrint('✅ Gemini API response received');

        final parsedResponse = _parseResponse(response);
        final validatedResponse = await _validateRecommendations(parsedResponse);

        if (validatedResponse.recommendedSubjectAreas.isEmpty) {
          throw Exception('No valid recommendations generated');
        }

        return validatedResponse;

      } catch (e) {
        lastException = e as Exception;
        retryCount++;

        if (retryCount <= _maxRetries) {
          debugPrint('⚠️ Attempt $retryCount failed: $e');
          debugPrint('🔄 Retrying in ${retryCount * 2} seconds...');
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          debugPrint('❌ All retry attempts exhausted');
        }
      }
    }

    throw lastException ?? Exception('Failed to generate matches after $_maxRetries retries');
  }

  /// Build comprehensive prompt for Gemini
  Future<String> _buildPrompt(AIMatchRequest request) async {
    final requestJson = jsonEncode(request.toJson());
    final availableSubjectAreas = await _getAvailableStudyAreas();

    if (availableSubjectAreas.isEmpty) {
      throw Exception('No subject areas available in database');
    }

    // Build user preferences summary for context
    final prefsContext = _buildPreferencesContext(request.preferences);

    return '''
You are an expert AI education advisor analyzing a student's profile to recommend suitable academic subject areas.

AVAILABLE SUBJECT AREAS (${availableSubjectAreas.length} total):
${availableSubjectAreas.join(', ')}

CRITICAL REQUIREMENTS:
1. Select subject areas ONLY from the list above
2. Match the EXACT spelling and capitalization
3. Return EXACTLY 5 recommendations, sorted by match score (highest first)
4. Base recommendations on ALL provided data
5. Consider the user's study preferences when making recommendations

STUDENT PROFILE:
$requestJson

USER STUDY PREFERENCES:
$prefsContext

ANALYSIS FRAMEWORK:

1. Academic Performance (40% weight):
   - Review all academic records, grades, CGPA
   - Identify academic strengths and patterns
   - Consider education level and progression

2. English Proficiency (10% weight):
   - Evaluate test results and bands
   - Ensure scores meet typical program requirements

3. Personality & Interests (30% weight):
   - Match personality traits (MBTI, RIASEC, OCEAN) with subject characteristics
   - Align stated interests with subject areas
   - Consider career paths that match personality

4. Study Preferences (20% weight):
   - Preferred study level and mode
   - Location preferences (if any)
   - Budget constraints
   - Other requirements

MATCHING LOGIC:
- Strong academic performance in related subjects = Higher match score
- Direct interest alignment = Boost match score
- Personality trait compatibility = Moderate boost
- Meets study preferences = Bonus points
- Career path alignment = Additional boost

OUTPUT REQUIREMENTS:
- Recommend EXACTLY 5 subject areas
- Match score: 0.70 to 1.00 (be realistic, not all matches are perfect)
- Comprehensive reasoning (150-200 words per recommendation)
- List 5-8 relevant skills per subject
- Map 2-4 user interests to each recommendation
- Include personality fit analysis (if data provided)
- Specify realistic difficulty level
- List applicable study modes
- Provide 6-10 specific career paths

RESPONSE FORMAT:
Return ONLY valid JSON without markdown formatting, code blocks, or explanatory text.
The response must start with { and end with }.

{
  "recommended_subject_areas": [
    {
      "subject_area": "EXACT match from available list",
      "match_score": 0.95,
      "reason": "Comprehensive 150-200 word explanation covering: (1) Academic strengths and how they align with this subject, (2) How your interests and activities directly relate, (3) Personality fit based on your profile, (4) How this matches your study preferences and constraints, (5) Career prospects and why they suit you. Be specific and personal, referencing actual data from their profile.",
      "top_skills": ["skill1", "skill2", "skill3", "skill4", "skill5", "skill6", "skill7", "skill8"],
      "related_interests": ["interest1", "interest2", "interest3"],
      "personality_fit": {
        "RIASEC": {"R": 0.7, "I": 0.9, "A": 0.5, "S": 0.6, "E": 0.4, "C": 0.7},
        "MBTI": "INTJ",
        "OCEAN": {"O": 0.8, "C": 0.7, "E": 0.4, "A": 0.6, "N": 0.3}
      },
      "difficulty_level": "Moderate",
      "study_modes": ["On Campus", "Online"],
      "career_paths": ["Career 1", "Career 2", "Career 3", "Career 4", "Career 5", "Career 6", "Career 7", "Career 8"]
    }
  ]
}
''';
  }

  /// Build preferences context for better matching
  String _buildPreferencesContext(UserPreferences prefs) {
    final context = StringBuffer();

    if (prefs.studyLevel != null) {
      context.writeln('- Preferred Study Level: ${prefs.studyLevel}');
    }

    if (prefs.mode != null) {
      context.writeln('- Preferred Study Mode: ${prefs.mode}');
    }

    if (prefs.locations.isNotEmpty) {
      context.writeln('- Preferred Locations: ${prefs.locations.join(", ")}');
    }

    if (prefs.tuitionMax != null) {
      context.writeln('- Maximum Tuition Budget: RM ${prefs.tuitionMax!.toStringAsFixed(0)}/year');
    }

    if (prefs.scholarshipRequired) {
      context.writeln('- Scholarship Required: Yes (prioritize subject areas with scholarship opportunities)');
    }

    if (prefs.workStudyImportant) {
      context.writeln('- Work-Study Important: Yes');
    }

    return context.isEmpty ? 'No specific preferences provided' : context.toString();
  }

  /// Get available study areas from database
  Future<List<String>> _getAvailableStudyAreas() async {
    try {
      final localDataSource = LocalDataSource.instance;
      final areas = await localDataSource.getAvailableSubjectAreas();

      if (areas.isEmpty) {
        debugPrint('⚠️ No subject areas found in database');
        return [];
      }

      // Clean and validate areas
      final cleanedAreas = areas
          .where((area) => area.trim().isNotEmpty)
          .map((area) => area.trim())
          .toSet() // Remove duplicates
          .toList();

      debugPrint('✅ Retrieved ${cleanedAreas.length} unique study areas');
      return cleanedAreas;

    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching study areas: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Call Gemini API with timeout and error handling
  Future<String> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(
        '${GeminiConfig.baseUrl}/models/${GeminiConfig.model}:generateContent?key=${GeminiConfig.apiKey}'
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE'
        }
      ]
    };

    debugPrint('📤 Sending request to Gemini API...');
    debugPrint('📊 Prompt length: ${prompt.length} characters');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        _timeout,
        onTimeout: () {
          throw Exception('Gemini API request timed out after ${_timeout.inSeconds} seconds');
        },
      );

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Gemini API request failed with status ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);

      // Validate response structure
      if (responseData['candidates'] == null ||
          (responseData['candidates'] as List).isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final content = responseData['candidates'][0]['content'];
      if (content == null ||
          content['parts'] == null ||
          (content['parts'] as List).isEmpty) {
        throw Exception('Invalid response structure from Gemini');
      }

      final text = content['parts'][0]['text'] as String;

      if (text.trim().isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      debugPrint('✅ Received valid response (${text.length} characters)');
      return text;

    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('JSON parsing error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Parse Gemini response with robust error handling
  AIMatchResponse _parseResponse(String responseText) {
    try {
      // Clean the response
      String cleanedText = responseText.trim();

      // Remove markdown JSON formatting if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      // Validate JSON structure
      if (!cleanedText.startsWith('{') || !cleanedText.endsWith('}')) {
        throw FormatException('Response is not valid JSON format');
      }

      debugPrint('🔍 Parsing JSON response...');
      final jsonResponse = jsonDecode(cleanedText) as Map<String, dynamic>;

      // Validate required fields
      if (!jsonResponse.containsKey('recommended_subject_areas')) {
        throw FormatException('Missing "recommended_subject_areas" field');
      }

      final response = AIMatchResponse.fromJson(jsonResponse);

      // Validate we got recommendations
      if (response.recommendedSubjectAreas.isEmpty) {
        throw Exception('No recommendations in response');
      }

      debugPrint('✅ Successfully parsed ${response.recommendedSubjectAreas.length} recommendations');
      return response;

    } on FormatException catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      debugPrint('📄 Response text (first 500 chars): ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}');
      throw Exception('Failed to parse AI response: Invalid JSON format');
    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  /// Validate and correct recommendations against database
  Future<AIMatchResponse> _validateRecommendations(
      AIMatchResponse response,
      ) async {
    try {
      final localDataSource = LocalDataSource.instance;
      final availableAreas = await localDataSource.getAvailableSubjectAreas();

      if (availableAreas.isEmpty) {
        debugPrint('⚠️ No available areas to validate against');
        return response;
      }

      // Create case-insensitive map for faster lookup
      final areaMap = <String, String>{};
      for (var area in availableAreas) {
        areaMap[area.toLowerCase().trim()] = area;
      }

      final validated = <RecommendedSubjectArea>[];
      int exactMatches = 0;
      int fuzzyMatches = 0;
      int noMatches = 0;

      for (var rec in response.recommendedSubjectAreas) {
        final key = rec.subjectArea.toLowerCase().trim();

        if (areaMap.containsKey(key)) {
          // Exact match (case-insensitive)
          exactMatches++;
          validated.add(
            RecommendedSubjectArea(
              subjectArea: areaMap[key]!,
              matchScore: rec.matchScore,
              reason: rec.reason,
              topSkills: rec.topSkills,
              relatedInterests: rec.relatedInterests,
              personalityFit: rec.personalityFit,
              difficultyLevel: rec.difficultyLevel,
              studyModes: rec.studyModes,
              careerPaths: rec.careerPaths,
            ),
          );
        } else {
          // Try fuzzy matching
          String? closestMatch;
          int closestDistance = 999;

          for (var area in availableAreas) {
            final distance = _levenshteinDistance(
              key,
              area.toLowerCase().trim(),
            );

            if (distance < closestDistance && distance <= 3) {
              closestDistance = distance;
              closestMatch = area;
            }
          }

          if (closestMatch != null) {
            fuzzyMatches++;
            debugPrint('🔍 Fuzzy matched "${rec.subjectArea}" → "$closestMatch" (distance: $closestDistance)');

            validated.add(
              RecommendedSubjectArea(
                subjectArea: closestMatch,
                matchScore: rec.matchScore * 0.97, // Slight penalty for fuzzy match
                reason: rec.reason,
                topSkills: rec.topSkills,
                relatedInterests: rec.relatedInterests,
                personalityFit: rec.personalityFit,
                difficultyLevel: rec.difficultyLevel,
                studyModes: rec.studyModes,
                careerPaths: rec.careerPaths,
              ),
            );
          } else {
            noMatches++;
            debugPrint('❌ Could not match "${rec.subjectArea}" to any database area');
          }
        }
      }

      debugPrint('📊 Validation results:');
      debugPrint('   ✅ Exact matches: $exactMatches');
      debugPrint('   🔍 Fuzzy matches: $fuzzyMatches');
      debugPrint('   ❌ No matches: $noMatches');

      if (validated.isEmpty) {
        throw Exception('No valid recommendations after validation');
      }

      return AIMatchResponse(recommendedSubjectAreas: validated);

    } catch (e) {
      debugPrint('⚠️ Validation error: $e');
      return response; // Return original if validation fails
    }
  }

  /// Calculate Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> costs = List<int>.generate(s2.length + 1, (i) => i);

    for (int i = 1; i <= s1.length; i++) {
      int lastCost = i - 1;
      costs[0] = i;

      for (int j = 1; j <= s2.length; j++) {
        final newCost = s1[i - 1] == s2[j - 1]
            ? lastCost
            : [lastCost, costs[j], costs[j - 1]].reduce((a, b) => a < b ? a : b) + 1;

        lastCost = costs[j];
        costs[j] = newCost;
      }
    }

    return costs[s2.length];
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse(
          '${GeminiConfig.baseUrl}/models/${GeminiConfig.model}?key=${GeminiConfig.apiKey}'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      final success = response.statusCode == 200;

      if (success) {
        debugPrint('✅ Gemini API connection successful');
      } else {
        debugPrint('❌ Gemini API connection failed: ${response.statusCode}');
      }

      return success;

    } catch (e) {
      debugPrint('❌ Gemini API connection test failed: $e');
      return false;
    }
  }
}