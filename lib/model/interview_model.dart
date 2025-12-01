import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================================================
/// INTERVIEW QUESTION (single item inside InterviewSession.questions)
/// ===============================================================
class InterviewQuestion {
  final String questionId;
  final String questionType; // e.g. Technical, Behavioral, etc.
  final String questionText;
  final String? userAnswer;   // nullable until answered
  final int? aiScore;         // 0..10 or 0..100 depending on evaluation
  final String? aiFeedback;   // short feedback from AI

  const InterviewQuestion({
    required this.questionId,
    required this.questionType,
    required this.questionText,
    this.userAnswer,
    this.aiScore,
    this.aiFeedback,
  });

  /// Firestore / JSON → InterviewQuestion
  factory InterviewQuestion.fromMap(Map<String, dynamic> map) {
    return InterviewQuestion(
      questionId: (map['questionId'] ?? '').toString(),
      questionType: (map['questionType'] ?? '').toString(),
      questionText: (map['questionText'] ?? '').toString(),
      userAnswer: map['userAnswer']?.toString(),
      aiScore: _asInt(map['aiScore']),
      aiFeedback: map['aiFeedback']?.toString(),
    );
  }

  /// Gemini JSON (same as fromMap, provided for clarity)
  factory InterviewQuestion.fromGemini(Map<String, dynamic> map) =>
      InterviewQuestion.fromMap(map);

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionType': questionType,
      'questionText': questionText,
      if (userAnswer != null) 'userAnswer': userAnswer,
      if (aiScore != null) 'aiScore': aiScore,
      if (aiFeedback != null) 'aiFeedback': aiFeedback,
    };
  }

  InterviewQuestion copyWith({
    String? questionId,
    String? questionType,
    String? questionText,
    String? userAnswer,
    int? aiScore,
    String? aiFeedback,
  }) {
    return InterviewQuestion(
      questionId: questionId ?? this.questionId,
      questionType: questionType ?? this.questionType,
      questionText: questionText ?? this.questionText,
      userAnswer: userAnswer ?? this.userAnswer,
      aiScore: aiScore ?? this.aiScore,
      aiFeedback: aiFeedback ?? this.aiFeedback,
    );
  }
}

/// ===============================================================
/// INTERVIEW SESSION (root doc at users/{uid}/interview/{sessionId})
/// ===============================================================
class InterviewSession {
  final String id;                // Firestore document id (e.g. I0001)
  final String jobTitle;          // e.g. "Software Engineer"
  final String difficultyLevel;   // "Beginner" | "Intermediate" | "Advanced"
  final int sessionDuration;      // minutes (15..60)
  final int numQuestions;         // 5..10
  final List<String> questionCategories; // e.g. ["Technical","Behavioral"]

  final Timestamp? startTime;     // Firestore Timestamp
  final Timestamp? endTime;       // Firestore Timestamp

  // Scores (0..100) — content(40) + comm(30) + response(20) + confidence(10)
  final int? totalScore;
  final int? contentScore;
  final int? communicationScore;
  final int? responseTimeScore;
  final int? confidenceScore;

  final String? feedback;               // overall feedback paragraph
  final List<String>? recommendations;  // next steps bullet points
  final List<InterviewQuestion> questions;

  final bool isRetake;                  // if this is a retake of previous set
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const InterviewSession({
    required this.id,
    required this.jobTitle,
    required this.difficultyLevel,
    required this.sessionDuration,
    required this.numQuestions,
    required this.questionCategories,
    required this.questions,
    this.startTime,
    this.endTime,
    this.totalScore,
    this.contentScore,
    this.communicationScore,
    this.responseTimeScore,
    this.confidenceScore,
    this.feedback,
    this.recommendations,
    this.isRetake = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory for a blank/new session shell
  factory InterviewSession.empty(String id) => InterviewSession(
    id: id,
    jobTitle: '',
    difficultyLevel: 'Beginner',
    sessionDuration: 30,
    numQuestions: 5,
    questionCategories: const [],
    questions: const [],
    isRetake: false,
  );

  /// Firestore DocumentSnapshot → InterviewSession
  factory InterviewSession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return InterviewSession.fromMap(data, id: doc.id);
  }

  /// Generic Map (Firestore/JSON) → InterviewSession
  factory InterviewSession.fromMap(Map<String, dynamic> map, {required String id}) {
    return InterviewSession(
      id: id,
      jobTitle: (map['jobTitle'] ?? '').toString(),
      difficultyLevel: (map['difficultyLevel'] ?? '').toString(),
      sessionDuration: _asInt(map['sessionDuration']) ?? 30,
      numQuestions: _asInt(map['numQuestions']) ?? 5,
      questionCategories: _asListString(map['questionCategories']),
      startTime: _asTimestamp(map['startTime']),
      endTime: _asTimestamp(map['endTime']),
      totalScore: _asInt(map['totalScore']),
      contentScore: _asInt(map['contentScore']),
      communicationScore: _asInt(map['communicationScore']),
      responseTimeScore: _asInt(map['responseTimeScore']),
      confidenceScore: _asInt(map['confidenceScore']),
      feedback: map['feedback']?.toString(),
      recommendations: _asListString(map['recommendations']),
      questions: (map['questions'] as List<dynamic>? ?? const [])
          .map((e) => InterviewQuestion.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      isRetake: (map['isRetake'] as bool?) ?? false,
      createdAt: _asTimestamp(map['createdAt']),
      updatedAt: _asTimestamp(map['updatedAt']),
    );
  }

  /// Gemini JSON → InterviewSession
  /// Expecting JSON with keys aligned to Firestore fields (except id, timestamps)
  /// If you receive JSON string, decode first: InterviewSession.fromGeminiJson(jsonDecode(txt), id: 'I0001')
  factory InterviewSession.fromGeminiJson(Map<String, dynamic> json, {required String id}) {
    return InterviewSession(
      id: id,
      jobTitle: (json['jobTitle'] ?? '').toString(),
      difficultyLevel: (json['difficultyLevel'] ?? '').toString(),
      sessionDuration: _asInt(json['sessionDuration']) ?? 30,
      numQuestions: _asInt(json['numQuestions']) ?? 5,
      questionCategories: _asListString(json['questionCategories']),
      startTime: null,  // set by app when session actually starts
      endTime: null,
      totalScore: null, // set after evaluation
      contentScore: null,
      communicationScore: null,
      responseTimeScore: null,
      confidenceScore: null,
      feedback: null,
      recommendations: const [],
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((e) => InterviewQuestion.fromGemini(Map<String, dynamic>.from(e)))
          .toList(),
      isRetake: false,
      createdAt: null,
      updatedAt: null,
    );
  }

  /// InterviewSession → Map (for Firestore)
  Map<String, dynamic> toMap({bool includeTimestamps = true}) {
    return {
      'jobTitle': jobTitle,
      'difficultyLevel': difficultyLevel,
      'sessionDuration': sessionDuration,
      'numQuestions': numQuestions,
      'questionCategories': questionCategories,
      'startTime': startTime,
      'endTime': endTime,
      'totalScore': totalScore,
      'contentScore': contentScore,
      'communicationScore': communicationScore,
      'responseTimeScore': responseTimeScore,
      'confidenceScore': confidenceScore,
      if (feedback != null) 'feedback': feedback,
      if (recommendations != null) 'recommendations': recommendations,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isRetake': isRetake,
      if (includeTimestamps) 'createdAt': createdAt,
      if (includeTimestamps) 'updatedAt': updatedAt,
    };
  }

  /// Optional: pretty JSON
  String toJson() => jsonEncode(toMap());

  InterviewSession copyWith({
    String? id,
    String? jobTitle,
    String? difficultyLevel,
    int? sessionDuration,
    int? numQuestions,
    List<String>? questionCategories,
    Timestamp? startTime,
    Timestamp? endTime,
    int? totalScore,
    int? contentScore,
    int? communicationScore,
    int? responseTimeScore,
    int? confidenceScore,
    String? feedback,
    List<String>? recommendations,
    List<InterviewQuestion>? questions,
    bool? isRetake,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return InterviewSession(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      numQuestions: numQuestions ?? this.numQuestions,
      questionCategories: questionCategories ?? this.questionCategories,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalScore: totalScore ?? this.totalScore,
      contentScore: contentScore ?? this.contentScore,
      communicationScore: communicationScore ?? this.communicationScore,
      responseTimeScore: responseTimeScore ?? this.responseTimeScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      feedback: feedback ?? this.feedback,
      recommendations: recommendations ?? this.recommendations,
      questions: questions ?? this.questions,
      isRetake: isRetake ?? this.isRetake,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// =======================
/// Helpers (robust casting)
/// =======================
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString());
}

List<String> _asListString(dynamic v) {
  if (v == null) return <String>[];
  if (v is List) return v.map((e) => e.toString()).toList();
  return <String>[];
}

Timestamp? _asTimestamp(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v;
  if (v is DateTime) return Timestamp.fromDate(v);
  // If Gemini returns ISO8601 string → parse to Timestamp
  if (v is String) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return Timestamp.fromDate(dt);
  }
  return null;
}
