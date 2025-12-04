// lib/services/ai_career_service.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_wise/model/career_suggestion.dart';
import 'package:path_wise/model/careerroadmap_model.dart';
import 'package:path_wise/model/user_profile.dart';
import 'package:path_wise/viewModel/profile_view_model.dart';

class AiService {
  final String apiKey = 'AIzaSyDOmbENlNrvNacS9fCbUqD9PSyEhilP9Ss';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Correct Gemini API endpoint
  String get apiUrl => 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

  /// Main method to get career suggestions from Gemini AI
  Future<Map<String, dynamic>> getCareerSuggestions(
      ProfileViewModel profileVM) async {
    final UserProfile? userProfile = profileVM.profile;
    if (userProfile == null) {
      throw Exception("User profile is missing!");
    }

    final prompt = _createGeminiPrompt(userProfile);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Extract the text from Gemini response
        final textContent = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textContent == null) {
          throw Exception("No content in AI response");
        }

        // Parse the JSON string returned by Gemini
        final aiPredictions = json.decode(textContent) as Map<String, dynamic>;
        return aiPredictions;
      } else {
        throw Exception("Failed to fetch career suggestions. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error in AI request: $e");
    }
  }

  /// Generate Career Roadmap for a specific job title
  /// First checks Firestore for existing roadmap with same job title
  /// If found, returns cached data. If not, generates new one via Gemini AI
  Future<Map<String, dynamic>> generateCareerRoadmap({
    required String jobTitle,
    required UserProfile userProfile,
    String? uid, // Optional: needed to check user-specific Firestore
  }) async {
    try {
      // Step 1: Check if roadmap already exists in Firestore
      if (uid != null) {
        debugPrint('🔍 Searching Firestore for existing roadmap: "$jobTitle"');

        final existingRoadmapSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('careerroadmap')
            .where('jobTitle', isEqualTo: jobTitle)
            .limit(1)
            .get();

        if (existingRoadmapSnapshot.docs.isNotEmpty) {
          debugPrint('✅ Found existing roadmap in Firestore! Skipping AI call.');

          // Get the existing roadmap document
          final existingRoadmapDoc = existingRoadmapSnapshot.docs.first;
          final existingRoadmapData = existingRoadmapDoc.data();

          // Get the roadmap ID
          final roadmapId = existingRoadmapDoc.id;

          // Find the associated skill gap
          final skillGapSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .collection('skillgap')
              .where('careerRoadmapId', isEqualTo: roadmapId)
              .limit(1)
              .get();

          List<Map<String, dynamic>> skillGapsData = [];

          if (skillGapSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Found existing skill gap for roadmap: $roadmapId');
            final skillGapDoc = skillGapSnapshot.docs.first;
            final skillGapData = skillGapDoc.data();
            skillGapsData = List<Map<String, dynamic>>.from(skillGapData['skillgaps'] ?? []);
          } else {
            debugPrint('⚠️ No skill gap found. Will generate new skill gap based on user profile.');
            // Generate skill gaps based on user's current skills vs roadmap requirements
            skillGapsData = _generateSkillGapsFromRoadmap(existingRoadmapData, userProfile);
          }

          // Return cached roadmap with skill gaps
          return {
            'roadmap': existingRoadmapData,
            'skillGaps': skillGapsData,
            'fromCache': true, // Flag to indicate data is from cache
            'roadmapId': roadmapId,
          };
        }

        debugPrint('❌ No existing roadmap found. Generating new one via AI...');
      }

      // Step 2: No existing roadmap found, generate via Gemini AI
      final prompt = _createCareerRoadmapPrompt(jobTitle, userProfile);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final textContent = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textContent == null) {
          throw Exception("No content in AI response for career roadmap");
        }

        final roadmapData = json.decode(textContent) as Map<String, dynamic>;
        roadmapData['fromCache'] = false; // Flag to indicate fresh AI generation

        debugPrint('✅ Generated new roadmap via Gemini AI');
        return roadmapData;
      } else {
        throw Exception("Failed to generate career roadmap. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error generating career roadmap: $e");
    }
  }

  /// Helper method to generate skill gaps by comparing user skills with roadmap requirements
  List<Map<String, dynamic>> _generateSkillGapsFromRoadmap(
      Map<String, dynamic> roadmapData,
      UserProfile userProfile,
      ) {
    try {
      final roadmapStages = roadmapData['roadmap'] as List<dynamic>?;
      if (roadmapStages == null || roadmapStages.isEmpty) return [];

      // Get the first stage (entry level) requirements
      final firstStage = roadmapStages.first as Map<String, dynamic>;
      final requiredSkills = List<String>.from(firstStage['requiredSkills'] ?? []);

      // Get user's current skills
      final userSkills = userProfile.skills ?? [];
      final userSkillMap = <String, int>{};
      for (var skill in userSkills) {
        userSkillMap[skill.name ?? ''] = skill.level ?? 0;
      }

      // Calculate skill gaps
      List<Map<String, dynamic>> skillGaps = [];

      for (var requiredSkill in requiredSkills) {
        final userLevel = userSkillMap[requiredSkill] ?? 0;
        final requiredLevel = 4; // Default required level for entry position

        if (userLevel < requiredLevel) {
          final gap = requiredLevel - userLevel;
          String priority;

          if (gap >= 3 || userLevel == 0) {
            priority = 'Critical';
          } else if (gap == 2) {
            priority = 'High';
          } else {
            priority = 'Medium';
          }

          skillGaps.add({
            'skillName': requiredSkill,
            'userProficiencyLevel': userLevel,
            'requiredProficiencyLevel': requiredLevel,
            'priorityLevel': priority,
          });
        }
      }

      debugPrint('📊 Generated ${skillGaps.length} skill gaps from cached roadmap');
      return skillGaps;
    } catch (e) {
      debugPrint('⚠️ Error generating skill gaps from roadmap: $e');
      return [];
    }
  }

  /// Generate Learning Resources for skill gaps
  Future<Map<String, dynamic>> generateLearningResources({
    required List<SkillGapEntry> skillGaps,
  }) async {
    final prompt = _createLearningResourcesPrompt(skillGaps);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final textContent = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textContent == null) {
          throw Exception("No content in AI response for learning resources");
        }

        final resourcesData = json.decode(textContent) as Map<String, dynamic>;
        return resourcesData;
      } else {
        throw Exception("Failed to generate learning resources. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error generating learning resources: $e");
    }
  }

  /// Helper: Builds the prediction JSON payload based on UserProfile
  Map<String, dynamic> _buildPredictionRequest(UserProfile userProfile) {
    return {
      "location": {
        "city": userProfile.city ?? "Unknown",
        "state": userProfile.state ?? "Unknown",
        "country": userProfile.country ?? "Malaysia",
      },
      "education": userProfile.education?.map((edu) {
        return {
          "degreeLevel": edu.degreeLevel ?? "Unknown",
          "fieldOfStudy": edu.fieldOfStudy ?? "Unknown",
          "gpa": edu.gpa ?? "",
          "isCurrent": edu.isCurrent ?? false,
        };
      }).toList() ?? [],
      "skills": userProfile.skills?.map((skill) {
        return {
          "name": skill.name ?? "Unknown",
          "category": skill.category ?? "Unknown",
          "proficiency": skill.level ?? 1,
          "levelText": skill.levelText ?? "",
        };
      }).toList() ?? [],
      "experience": userProfile.experience?.map((exp) {
        final startDate = exp.startDate?.toDate();
        final endDate = exp.isCurrent == true ? DateTime.now() : exp.endDate?.toDate();

        double years = 0.0;
        if (startDate != null && endDate != null) {
          years = endDate.difference(startDate).inDays / 365.0;
        }

        return {
          "yearsOfExperience": years.toStringAsFixed(1),
          "jobTitle": exp.jobTitle ?? "Unknown",
          "employmentType": exp.employmentType ?? "Unknown",
          "industry": exp.industry ?? "Unknown",
          "company": exp.company ?? "Unknown",
          "isCurrent": exp.isCurrent ?? false,
          "achievements": exp.achievements?.description ?? "",
          "skillsUsed": exp.achievements?.skillsUsed ?? [],
        };
      }).toList() ?? [],
      "personality": {
        "mbti": userProfile.mbti ?? null,
        "riasec": userProfile.riasec ?? null,
      },
      "preferences": {
        "desiredJobTitles": userProfile.preferences?.desiredJobTitles ?? [],
        "industries": userProfile.preferences?.industries ?? [],
        "companySize": userProfile.preferences?.companySize ?? "Any",
        "workEnvironment": userProfile.preferences?.workEnvironment ?? [],
        "preferredLocations": userProfile.preferences?.preferredLocations ?? [],
        "willingToRelocate": userProfile.preferences?.willingToRelocate ?? false,
        "salaryExpectation": {
          "min": userProfile.preferences?.salary?.min ?? 0,
          "max": userProfile.preferences?.salary?.max ?? 0,
          "type": userProfile.preferences?.salary?.type ?? "Monthly",
        },
      },
    };
  }

  /// Create prompt for career suggestions
  String _createGeminiPrompt(UserProfile p) {
    final profileData = _buildPredictionRequest(p);
    return """
You are a career guidance assistant. Based on the user's profile data below, analyze their education, skills, experience, personality traits, and preferences to recommend the most suitable careers in Malaysia.

### User Profile (JSON)
${jsonEncode(profileData)}

### Requirements:
1. Analyze all data points:
   - **education**: Consider degree level, field of study, GPA, and whether the user is still studying.
   - **skills**: Interpret skill proficiency (1–5) and identify whether they are technical or soft skills.
   - **experience**: Calculate years of experience. Consider job title, employment type, industry, and achievements.
   - **personality**: Interpret MBTI and RIASEC codes. If either is missing, note it.
   - **preferences**: Align recommendations with desired job titles and preferred industries.

2. Generate a ranked list of up to 5 most suitable career paths.

3. For each recommended career, provide:
   - `job_title` (string) - Name of the job role
   - `short_description` (string) - Brief explanation about the job role (2-3 sentences)
   - `reasons` (array of strings) - 3-5 specific reasons why this career fits the user's profile
   - `fit_score` (integer, 0-100) - How closely the career matches the user profile
   - `avg_salary_MYR` (object) - Salary range with "min" and "max" keys in MYR (Malaysian Ringgit)
   - `job_growth` (string) - Market demand: "Low" / "Moderate" / "High" / "Very High"
   - `jobsDescription` (string) - Detailed description of typical job responsibilities (3-4 sentences)
   - `top_skills_needed` (array of strings) - 4-6 key skills needed for this career
   - `suggested_next_steps` (array of strings) - 3-4 actionable suggestions for career development

4. Return ONLY valid JSON in this exact format:

{
  "predictions": [
    {
      "job_title": "Software Developer",
      "short_description": "Design and build software applications using programming languages.",
      "reasons": [
        "Strong programming skills in Java and Python",
        "Computer Science degree aligns with technical requirements",
        "Previous internship experience in software development"
      ],
      "fit_score": 92,
      "avg_salary_MYR": {
        "min": 4000,
        "max": 8000
      },
      "job_growth": "High",
      "jobsDescription": "Software developers create, test, and maintain software applications. They work with programming languages to build solutions that meet user needs. They collaborate with teams to design system architecture and ensure code quality.",
      "top_skills_needed": ["Java", "Python", "Problem Solving", "Git", "REST APIs"],
      "suggested_next_steps": [
        "Build a portfolio with 3-5 projects on GitHub",
        "Learn cloud platforms like AWS or Azure",
        "Contribute to open-source projects"
      ]
    }
  ],
  "missing_data": {
    "mbti": false,
    "riasec": false,
    "skills": false,
    "experience": false
  }
}

IMPORTANT: Return ONLY the JSON object. Do not include any markdown formatting, code blocks, or explanatory text.
""";
  }

  /// Create prompt for career roadmap generation
  String _createCareerRoadmapPrompt(String jobTitle, UserProfile userProfile) {
    final userSkills = userProfile.skills?.map((skill) {
      return {
        "name": skill.name ?? "Unknown",
        "proficiency": skill.level ?? 1,
        "levelText": skill.levelText ?? "",
      };
    }).toList() ?? [];

    return """
You are a career progression advisor. Generate a comprehensive career roadmap for the target job title: "$jobTitle" based on the user's current skills and profile in Malaysia.

### User Current Skills (with proficiency levels 1-5):
${jsonEncode(userSkills)}

### Requirements:

1. Create a career progression roadmap with 3-5 stages, starting from an entry-level position progressing to senior/leadership roles.
   Example progression: Junior Developer → Mid-Level Developer → Senior Developer → Team Lead → Engineering Manager

2. For EACH career stage, provide:
   - `jobTitle` (string) - The position title for this stage
   - `requiredSkills` (array of strings) - 5-8 key skills needed at this level
   - `estimatedTimeframe` (string) - Typical time to reach this stage (e.g., "2-3 years", "Entry Level")
   - `progressionMilestones` (array of strings) - 3-5 key achievements needed to advance (e.g., "Lead 2+ major projects", "Mentor junior developers")
   - `responsibilities` (string) - Detailed description of job responsibilities (3-4 sentences)
   - `salaryRange` (string) - Expected salary range in Malaysia (e.g., "RM 4,000 - RM 6,000")

3. Analyze skill gaps by comparing user's current skills with the FIRST stage (entry-level) requirements:
   - For each required skill not possessed or with lower proficiency, create a skill gap entry
   - Calculate gap severity based on proficiency difference
   - Assign priority levels: "Critical" (gap > 3 levels), "High" (gap 2-3 levels), "Medium" (gap 1 level)

4. Return ONLY valid JSON in this exact format:

{
  "roadmap": {
    "jobTitle": "$jobTitle",
    "roadmap": [
      {
        "jobTitle": "Junior Software Developer",
        "requiredSkills": ["JavaScript", "HTML/CSS", "Git", "React", "REST APIs"],
        "estimatedTimeframe": "Entry Level",
        "progressionMilestones": [
          "Complete onboarding and training program",
          "Successfully deliver 2-3 small features independently",
          "Participate in code reviews and learn team practices"
        ],
        "responsibilities": "Write clean, maintainable code under supervision. Collaborate with team members on feature development. Participate in daily standups and sprint planning. Fix bugs and implement minor features. Learn and apply coding best practices.",
        "salaryRange": "RM 3,500 - RM 5,000"
      },
      {
        "jobTitle": "Software Developer",
        "requiredSkills": ["JavaScript", "React", "Node.js", "Git", "REST APIs", "Database Design", "Testing"],
        "estimatedTimeframe": "2-3 years",
        "progressionMilestones": [
          "Lead development of 2+ medium-sized features",
          "Demonstrate strong problem-solving abilities",
          "Contribute to technical discussions and architecture decisions"
        ],
        "responsibilities": "Design and implement features independently. Write comprehensive tests for code quality. Participate in architecture discussions. Mentor junior developers. Review code and provide constructive feedback. Optimize application performance.",
        "salaryRange": "RM 5,000 - RM 7,500"
      }
    ]
  },
  "skillGaps": [
    {
      "skillName": "React",
      "userProficiencyLevel": 2,
      "requiredProficiencyLevel": 4,
      "priorityLevel": "High"
    },
    {
      "skillName": "Git",
      "userProficiencyLevel": 0,
      "requiredProficiencyLevel": 3,
      "priorityLevel": "Critical"
    }
  ]
}

IMPORTANT: 
- Compare user skills against the ENTRY-LEVEL stage only for skill gap analysis
- If user doesn't have a skill, set userProficiencyLevel to 0
- Ensure all salary ranges are in Malaysian Ringgit (RM)
- Return ONLY the JSON object without any markdown formatting or explanatory text
""";
  }

  /// Create prompt for learning resources generation
  String _createLearningResourcesPrompt(List<SkillGapEntry> skillGaps) {
    final skillsData = skillGaps.map((gap) {
      return {
        "skillName": gap.skillName,
        "currentLevel": gap.userProficiencyLevel,
        "requiredLevel": gap.requiredProficiencyLevel,
        "priority": gap.priorityLevel,
      };
    }).toList();

    return """
You are an educational resource advisor. Recommend learning resources (courses, certifications) for the following skill gaps that a user needs to improve in Malaysia.

### Skill Gaps to Address:
${jsonEncode(skillsData)}

### Requirements:

1. For EACH skill gap, provide 2-4 learning resources that are:
   - Currently available online (Coursera, Udemy, edX, LinkedIn Learning, local Malaysian platforms)
   - Highly rated (4.0+ stars)
   - Relevant to the Malaysian job market
   - Mix of free and paid options when possible

2. For each learning resource, provide:
   - `courseName` (string) - Full course title
   - `provider` (string) - Platform name (e.g., "Coursera", "Udemy", "edX")
   - `courseLink` (string) - Direct URL to the course (must be valid and accessible)
   - `cost` (integer) - Approximate cost in MYR (use 0 for free courses, estimate conversion for USD courses)
   - `certification` (string) - Certificate name if available, or "No Certificate" if not offered

3. Prioritize resources based on:
   - Priority level of the skill gap (Critical > High > Medium)
   - Comprehensive coverage from beginner to required level
   - Practical, hands-on learning approach
   - Recognition in Malaysian job market

4. Return ONLY valid JSON in this exact format:

{
  "resources": [
    {
      "courseName": "The Complete JavaScript Course 2024: From Zero to Expert",
      "provider": "Udemy",
      "courseLink": "https://www.udemy.com/course/the-complete-javascript-course/",
      "cost": 89,
      "certification": "Udemy Certificate of Completion"
    },
    {
      "courseName": "JavaScript Algorithms and Data Structures",
      "provider": "freeCodeCamp",
      "courseLink": "https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/",
      "cost": 0,
      "certification": "freeCodeCamp Certification"
    },
    {
      "courseName": "Meta Front-End Developer Professional Certificate",
      "provider": "Coursera",
      "courseLink": "https://www.coursera.org/professional-certificates/meta-front-end-developer",
      "cost": 180,
      "certification": "Meta Front-End Developer Certificate"
    }
  ]
}

IMPORTANT:
- Provide real, existing courses with valid URLs
- Focus on popular, well-reviewed courses
- Include a mix of beginner to advanced resources based on proficiency gaps
- Ensure cost estimates are reasonable for Malaysian market
- Return ONLY the JSON object without any markdown formatting or explanatory text
""";
  }

  /// Generate next career roadmap ID (CR0001, CR0002, etc.)
  Future<String> _generateNextCareerRoadmapId(String uid) async {
    final roadmapRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('careerroadmap');

    final snapshot = await roadmapRef.get();
    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('CR') && docId.length >= 3) {
        final numberPart = docId.substring(2);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'CR${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Generate next skill gap ID (SG0001, SG0002, etc.)
  Future<String> _generateNextSkillGapId(String uid) async {
    final skillGapRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('skillgap');

    final snapshot = await skillGapRef.get();
    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('SG') && docId.length >= 3) {
        final numberPart = docId.substring(2);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'SG${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Generate next learning resource ID (LR0001, LR0002, etc.)
  Future<String> _generateNextLearningResourceId(String uid) async {
    final resourceRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('learningresources');

    final snapshot = await resourceRef.get();
    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('LR') && docId.length >= 3) {
        final numberPart = docId.substring(2);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'LR${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Save Career Roadmap and Skill Gaps to Firestore
  /// Checks if roadmap for job title already exists before generating new one
  Future<Map<String, String>> saveCareerRoadmapToFirestore({
    required String uid,
    required String jobTitle,
    required UserProfile userProfile,
  }) async {
    try {
      // Generate roadmap (will check Firestore cache internally)
      debugPrint('🗺️ Processing roadmap request for: "$jobTitle"');

      final aiResponse = await generateCareerRoadmap(
        jobTitle: jobTitle,
        userProfile: userProfile,
        uid: uid, // Pass uid to enable Firestore checking
      );

      final bool fromCache = aiResponse['fromCache'] ?? false;
      final String? existingRoadmapId = aiResponse['roadmapId'];

      if (fromCache && existingRoadmapId != null) {
        // Roadmap was loaded from cache
        debugPrint('✅ Using cached roadmap: $existingRoadmapId');

        // Check if we need to generate a new skill gap
        final skillGapsData = aiResponse['skillGaps'] as List<dynamic>;

        if (skillGapsData.isEmpty) {
          debugPrint('⚠️ No skill gaps found, generating new ones...');
        }

        // Generate new skill gap ID for this user
        final skillGapId = await _generateNextSkillGapId(uid);

        // Parse and save skill gaps
        final skillGapEntries = skillGapsData
            .map((e) => SkillGapEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();

        final skillGap = SkillGap(
          careerRoadmapId: existingRoadmapId,
          skillgaps: skillGapEntries,
        );

        final skillGapRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('skillgap')
            .doc(skillGapId);

        await skillGapRef.set(skillGap.toMap());
        debugPrint('✅ Created new skill gap: $skillGapId for cached roadmap');

        return {
          'roadmapId': existingRoadmapId,
          'skillGapId': skillGapId,
          'isNew': 'false',
        };
      }

      // Roadmap is newly generated from AI, save it
      debugPrint('💾 Saving new roadmap generated by AI...');

      // Generate IDs
      final roadmapId = await _generateNextCareerRoadmapId(uid);
      final skillGapId = await _generateNextSkillGapId(uid);

      // Parse roadmap data
      final roadmapData = aiResponse['roadmap'] as Map<String, dynamic>;
      final careerRoadmap = CareerRoadmap.fromMap(roadmapData);

      // Parse skill gaps data
      final skillGapsData = aiResponse['skillGaps'] as List<dynamic>;
      final skillGapEntries = skillGapsData
          .map((e) => SkillGapEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final skillGap = SkillGap(
        careerRoadmapId: roadmapId,
        skillgaps: skillGapEntries,
      );

      // Save to Firestore
      final roadmapRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('careerroadmap')
          .doc(roadmapId);

      final skillGapRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('skillgap')
          .doc(skillGapId);

      await Future.wait([
        roadmapRef.set(careerRoadmap.toMap()),
        skillGapRef.set(skillGap.toMap()),
      ]);

      debugPrint('✅ Saved NEW Career Roadmap: $roadmapId and Skill Gap: $skillGapId');

      return {
        'roadmapId': roadmapId,
        'skillGapId': skillGapId,
        'isNew': 'true',
      };
    } catch (e) {
      debugPrint('❌ Error saving career roadmap: $e');
      throw Exception('Failed to save career roadmap: $e');
    }
  }

  /// Mark all previous learning resources as not latest
  Future<void> _markPreviousResourcesAsStale(String uid, String skillGapId) async {
    try {
      final previousResources = await _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .where('skillGapId', isEqualTo: skillGapId)
          .where('isLatest', isEqualTo: true)
          .get();

      if (previousResources.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in previousResources.docs) {
        batch.update(doc.reference, {'isLatest': false});
      }
      await batch.commit();

      debugPrint('Marked ${previousResources.docs.length} previous resources as stale');
    } catch (e) {
      debugPrint('Error marking previous resources as stale: $e');
    }
  }

  /// Save Learning Resources to Firestore
  Future<String> saveLearningResourcesToFirestore({
    required String uid,
    required String skillGapId,
    required List<SkillGapEntry> skillGaps,
  }) async {
    try {
      // Mark previous resources as not latest
      await _markPreviousResourcesAsStale(uid, skillGapId);

      // Generate learning resources from AI
      final aiResponse = await generateLearningResources(skillGaps: skillGaps);

      // Generate ID
      final resourceId = await _generateNextLearningResourceId(uid);

      // Parse resources data
      final resourcesData = aiResponse['resources'] as List<dynamic>;
      final resourceEntries = resourcesData
          .map((e) => LearningResourceEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final learningResource = LearningResource(
        skillGapId: skillGapId,
        isLatest: true,
        resources: resourceEntries,
      );

      // Save to Firestore
      final resourceRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('learningresources')
          .doc(resourceId);

      await resourceRef.set(learningResource.toMap());

      debugPrint('✅ Saved Learning Resources: $resourceId');
      return resourceId;
    } catch (e) {
      debugPrint('❌ Error saving learning resources: $e');
      throw Exception('Failed to save learning resources: $e');
    }
  }


  /// Mark a specific career suggestion as stale (isLatest = false)
  Future<void> markAsStale(String uid, String careerSuggestionId) async {
    try {
      final suggestionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .doc(careerSuggestionId);

      await suggestionRef.update({'isLatest': false});
      debugPrint('Career suggestion $careerSuggestionId marked as stale');
    } catch (e) {
      debugPrint('Error marking career suggestion as stale: $e');
      throw Exception('Failed to mark career suggestion as stale: $e');
    }
  }

  /// Mark all previous career suggestions as stale (isLatest = false)
  Future<void> _markAllPreviousAsStale(String uid) async {
    try {
      final previousSuggestions = await _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion')
          .where('isLatest', isEqualTo: true)
          .get();

      if (previousSuggestions.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (var doc in previousSuggestions.docs) {
        batch.update(doc.reference, {'isLatest': false});
      }
      await batch.commit();

      debugPrint('Marked ${previousSuggestions.docs.length} previous suggestions as stale');
    } catch (e) {
      debugPrint('Error marking previous suggestions as stale: $e');
      throw Exception('Failed to mark previous suggestions as stale: $e');
    }
  }

  /// Generate next career suggestion ID (CS0001, CS0002, etc.)
  Future<String> _generateNextCareerSuggestionId(String uid) async {
    final careerSuggestionsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('careersuggestion');

    final snapshot = await careerSuggestionsRef.get();
    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('CS') && docId.length >= 3) {
        final numberPart = docId.substring(2);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'CS${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Save career suggestion to Firestore
  Future<String> saveCareerSuggestionToFirestore(
      String uid, Map<String, dynamic> aiResponse, UserProfile p) async {
    try {
      await _markAllPreviousAsStale(uid);

      final nextId = await _generateNextCareerSuggestionId(uid);
      final matches = _parseCareerMatch(aiResponse);

      final careerSuggestion = CareerSuggestion(
        id: nextId,
        createdAt: DateTime.now(),
        modelVersion: 'gemini-1.5-pro',
        isLatest: true,
        profileCompletionPercent: (p.completionPercent ?? 0.0).toInt(),
        matches: matches,
      );

      final careerSuggestionsRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('careersuggestion');

      await careerSuggestionsRef.doc(nextId).set(careerSuggestion.toMap());

      debugPrint('Career suggestion $nextId saved successfully');
      return nextId;
    } catch (e) {
      throw Exception("Error saving to Firestore: $e");
    }
  }

  /// Parse career matches from AI response
  List<CareerMatch> _parseCareerMatch(Map<String, dynamic> aiResponse) {
    try {
      final predictions = aiResponse['predictions'];

      if (predictions == null || predictions is! List) {
        throw Exception("Invalid predictions format in AI response");
      }

      return predictions.map<CareerMatch>((match) {
        Map<String, num> salaryMap = {};
        if (match['avg_salary_MYR'] != null) {
          final salaryData = match['avg_salary_MYR'];
          if (salaryData is Map) {
            if (salaryData['min'] != null) {
              salaryMap['min'] = (salaryData['min'] as num).toDouble();
            }
            if (salaryData['max'] != null) {
              salaryMap['max'] = (salaryData['max'] as num).toDouble();
            }
          }
        }

        return CareerMatch(
          jobTitle: match['job_title']?.toString() ?? 'Unknown',
          shortDescription: match['short_description']?.toString() ?? '',
          fitScore: (match['fit_score'] as num?)?.toInt() ?? 0,
          avgSalaryMYR: salaryMap,
          jobGrowth: match['job_growth']?.toString() ?? 'Unknown',
          jobsDescription: match['jobsDescription']?.toString() ?? '',
          reasons: (match['reasons'] as List?)?.map((e) => e.toString()).toList() ?? [],
          topSkillsNeeded: (match['top_skills_needed'] as List?)?.map((e) => e.toString()).toList() ?? [],
          suggestedNextSteps: (match['suggested_next_steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
        );
      }).toList();
    } catch (e) {
      throw Exception("Error parsing career matches: $e");
    }
  }

  // ==================== INTERVIEW SIMULATOR FUNCTIONS ====================

  /// Generate Interview Questions based on job title and settings
  Future<Map<String, dynamic>> generateInterviewQuestions({
    required String jobTitle,
    required String difficultyLevel,
    required int numQuestions,
    required List<String> questionCategories,
    required int sessionDuration,
  }) async {
    final prompt = _createInterviewQuestionsPrompt(
      jobTitle: jobTitle,
      difficultyLevel: difficultyLevel,
      numQuestions: numQuestions,
      questionCategories: questionCategories,
      sessionDuration: sessionDuration,
    );

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.8,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final textContent = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textContent == null) {
          throw Exception("No content in AI response for interview questions");
        }

        final questionsData = json.decode(textContent) as Map<String, dynamic>;
        debugPrint('✅ Generated ${numQuestions} interview questions for $jobTitle');
        return questionsData;
      } else {
        throw Exception("Failed to generate interview questions. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error generating interview questions: $e");
    }
  }

  /// Evaluate Interview Responses and provide feedback
  Future<Map<String, dynamic>> evaluateInterviewResponses({
    required String jobTitle,
    required String difficultyLevel,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required int totalDuration,
    required int sessionDuration,
  }) async {
    final prompt = _createInterviewEvaluationPrompt(
      jobTitle: jobTitle,
      difficultyLevel: difficultyLevel,
      questionsAndAnswers: questionsAndAnswers,
      totalDuration: totalDuration,
      sessionDuration: sessionDuration,
    );

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.7,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final textContent = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (textContent == null) {
          throw Exception("No content in AI response for interview evaluation");
        }

        final evaluationData = json.decode(textContent) as Map<String, dynamic>;
        debugPrint('✅ Evaluation complete. Total Score: ${evaluationData['totalScore']}');
        return evaluationData;
      } else {
        throw Exception("Failed to evaluate interview. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error evaluating interview: $e");
    }
  }

  /// Create prompt for generating interview questions
  String _createInterviewQuestionsPrompt({
    required String jobTitle,
    required String difficultyLevel,
    required int numQuestions,
    required List<String> questionCategories,
    required int sessionDuration,
  }) {
    return """
You are an expert technical recruiter and interview coach. Generate personalized interview questions for a job interview in Malaysia.

### Interview Settings:
- **Job Title**: $jobTitle
- **Difficulty Level**: $difficultyLevel (Beginner/Intermediate/Advanced)
- **Number of Questions**: $numQuestions
- **Question Categories**: ${questionCategories.join(', ')}
- **Session Duration**: $sessionDuration minutes

### Question Categories Explanation:
- **Technical Skills**: Job-specific technical knowledge and skills
- **Behavioral**: Past experiences and how candidate handled situations (STAR method)
- **Situational**: Hypothetical scenarios to assess problem-solving
- **Company Fit**: Culture, values, work style alignment
- **Leadership**: Team management, decision-making, conflict resolution
- **Problem Solving**: Analytical thinking, creativity, logic
- **Communication**: Clarity, articulation, presentation skills
- **Adaptability**: Handling change, learning agility, flexibility

### Requirements:

1. Generate exactly $numQuestions questions distributed across the selected categories
2. Ensure questions match the difficulty level:
   - **Beginner**: Basic concepts, definitions, simple scenarios
   - **Intermediate**: Application of knowledge, moderate complexity
   - **Advanced**: Complex scenarios, strategic thinking, expert-level concepts

3. For each question, provide:
   - `questionId`: Unique ID (Q001, Q002, etc.)
   - `questionType`: Category of the question
   - `questionText`: The actual interview question

4. Questions should be:
   - Relevant to the Malaysian job market
   - Appropriate for the job title and difficulty level
   - Clear and professional
   - Open-ended to allow detailed responses
   - Realistic and commonly asked in actual interviews

5. Return ONLY valid JSON in this exact format:

{
  "questions": [
    {
      "questionId": "Q001",
      "questionType": "Technical Skills",
      "questionText": "Can you explain the difference between RESTful and GraphQL APIs, and when would you choose one over the other?"
    },
    {
      "questionId": "Q002",
      "questionType": "Behavioral",
      "questionText": "Tell me about a time when you had to deal with a difficult team member. How did you handle the situation and what was the outcome?"
    },
    {
      "questionId": "Q003",
      "questionType": "Problem Solving",
      "questionText": "If you noticed a critical bug in production right before a major release, how would you approach resolving it?"
    }
  ]
}

IMPORTANT: 
- Return ONLY the JSON object without any markdown formatting or explanatory text
- Generate exactly $numQuestions questions
- Distribute questions across the categories: ${questionCategories.join(', ')}
- Ensure difficulty matches: $difficultyLevel
""";
  }

  /// Create prompt for evaluating interview responses
  String _createInterviewEvaluationPrompt({
    required String jobTitle,
    required String difficultyLevel,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required int totalDuration,
    required int sessionDuration,
  }) {
    return """
You are an expert interview evaluator and career coach. Evaluate this candidate's interview performance for a $jobTitle position in Malaysia.

### Interview Context:
- **Job Title**: $jobTitle
- **Difficulty Level**: $difficultyLevel
- **Session Duration**: $sessionDuration minutes
- **Time Taken**: $totalDuration minutes
- **Questions Answered**: ${questionsAndAnswers.length}

### Candidate's Responses:
${jsonEncode(questionsAndAnswers)}

### Evaluation Requirements:

1. **Evaluate each question individually** and provide:
   - `questionId`: Same as provided
   - `aiScore`: Score from 0-10 for this specific answer
   - `aiFeedback`: Brief feedback (2-3 sentences) on what was good and what could be improved

2. **Calculate overall scores** using this formula:
   - **Content Score (40%)**: Quality, relevance, depth, accuracy of answers
   - **Communication Score (30%)**: Clarity, structure, professionalism, articulation
   - **Response Time Score (20%)**: Efficiency based on time taken vs session duration
   - **Confidence Score (10%)**: Assertiveness, completeness, no excessive hedging

3. **Scoring Guidelines**:
   - Individual Question Score: 0-10 (10 being excellent)
   - Total Score: 0-100 (sum of weighted category scores)
   - Content Score: 0-40 points
   - Communication Score: 0-30 points
   - Response Time Score: 0-20 points
   - Confidence Score: 0-10 points

4. **Response Time Scoring Logic**:
   - Completed in < 50% of time: 10-12 points (too rushed)
   - Completed in 50-75% of time: 18-20 points (excellent)
   - Completed in 75-90% of time: 15-17 points (good)
   - Completed in 90-100% of time: 12-14 points (acceptable)
   - Exceeded time: 8-10 points (poor time management)

5. **Provide overall feedback** (3-4 sentences):
   - Highlight key strengths
   - Identify main areas for improvement
   - Comment on overall interview performance

6. **Provide 3-5 actionable recommendations** for improvement:
   - Specific, measurable suggestions
   - Focus on most critical areas
   - Include resources or actions they can take

7. **Return ONLY valid JSON** in this exact format:

{
  "totalScore": 87,
  "contentScore": 35,
  "communicationScore": 26,
  "responseTimeScore": 17,
  "confidenceScore": 9,
  "feedback": "Overall strong performance with good technical knowledge. Your explanations were clear and well-structured. However, some answers could benefit from more specific examples. Time management was excellent, completing the interview efficiently without rushing.",
  "recommendations": [
    "Practice using the STAR method (Situation, Task, Action, Result) for behavioral questions to provide more structured responses",
    "Include more quantifiable achievements and metrics in your answers to demonstrate impact",
    "Prepare 2-3 detailed project examples that showcase different skills you can reference across multiple questions",
    "Work on providing more concise answers while maintaining depth - aim for 1-2 minutes per response",
    "Research common ${jobTitle} challenges in Malaysian companies to provide more localized examples"
  ],
  "questionEvaluations": [
    {
      "questionId": "Q001",
      "aiScore": 8,
      "aiFeedback": "Good technical explanation with clear understanding of concepts. You correctly identified key differences. However, adding a real-world example of when you used each approach would strengthen your answer."
    },
    {
      "questionId": "Q002",
      "aiScore": 7,
      "aiFeedback": "You demonstrated good conflict resolution skills. The answer would be stronger with more specific details about the outcome and lessons learned. Consider using the STAR method to structure behavioral responses."
    }
  ]
}

IMPORTANT:
- Be constructive and encouraging in feedback
- Scores should reflect the difficulty level ($difficultyLevel)
- Consider Malaysian workplace context
- Empty or skipped answers should receive 0 score with feedback: "Question was skipped. No response provided."
- Return ONLY the JSON object without markdown formatting
""";
  }

  /// Generate next interview session ID (I0001, I0002, etc.)
  Future<String> generateNextInterviewSessionId(String uid) async {
    final interviewRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('interview');

    final snapshot = await interviewRef.get();
    int maxNumber = 0;

    for (var doc in snapshot.docs) {
      final docId = doc.id;
      if (docId.startsWith('I') && docId.length >= 2) {
        final numberPart = docId.substring(1);
        final number = int.tryParse(numberPart);
        if (number != null && number > maxNumber) {
          maxNumber = number;
        }
      }
    }

    final nextNumber = maxNumber + 1;
    return 'I${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Save interview session to Firestore
  Future<String> saveInterviewSessionToFirestore({
    required String uid,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      // Generate session ID
      final sessionId = await generateNextInterviewSessionId(uid);

      // Add timestamps
      final now = Timestamp.now();
      sessionData['createdAt'] = now;
      sessionData['updatedAt'] = now;

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('interview')
          .doc(sessionId)
          .set(sessionData);

      debugPrint('✅ Saved interview session: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Error saving interview session: $e');
      throw Exception('Failed to save interview session: $e');
    }
  }
}