// lib/model/riasec_model.dart

class RiasecAnswerOption {
  final int value;
  final String name;

  RiasecAnswerOption({
    required this.value,
    required this.name,
  });

  factory RiasecAnswerOption.fromJson(Map<String, dynamic> json) {
    return RiasecAnswerOption(
      value: json['value'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'name': name,
    };
  }
}

class RiasecQuestion {
  final int index;
  final String area;
  final String text;

  RiasecQuestion({
    required this.index,
    required this.area,
    required this.text,
  });

  factory RiasecQuestion.fromJson(Map<String, dynamic> json) {
    return RiasecQuestion(
      index: json['index'] as int,
      area: json['area'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'area': area,
      'text': text,
    };
  }
}

class RiasecAnswer {
  final int questionIndex;
  final String area;
  final int value;

  RiasecAnswer({
    required this.questionIndex,
    required this.area,
    required this.value,
  });

  factory RiasecAnswer.fromJson(Map<String, dynamic> json) {
    return RiasecAnswer(
      questionIndex: json['questionIndex'] as int,
      area: json['area'] as String,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionIndex': questionIndex,
      'area': area,
      'value': value,
    };
  }
}

class RiasecTestProgress {
  final List<RiasecAnswer> answers;
  final int currentQuestionIndex;
  final DateTime lastUpdated;

  RiasecTestProgress({
    required this.answers,
    required this.currentQuestionIndex,
    required this.lastUpdated,
  });

  factory RiasecTestProgress.fromJson(Map<String, dynamic> json) {
    return RiasecTestProgress(
      answers: (json['answers'] as List<dynamic>)
          .map((answer) => RiasecAnswer.fromJson(answer as Map<String, dynamic>))
          .toList(),
      currentQuestionIndex: json['currentQuestionIndex'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
      'currentQuestionIndex': currentQuestionIndex,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  double get progressPercentage {
    if (answers.isEmpty) return 0.0;
    return answers.length / 60.0; // 60 questions total
  }
}

class RiasecInterestResult {
  final String href;
  final String code;
  final String title;
  final String description;
  final int score;

  RiasecInterestResult({
    required this.href,
    required this.code,
    required this.title,
    required this.description,
    required this.score,
  });

  factory RiasecInterestResult.fromJson(Map<String, dynamic> json) {
    return RiasecInterestResult(
      href: json['href'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'code': code,
      'title': title,
      'description': description,
      'score': score,
    };
  }

  // Get percentage score (0-100)
  int get percentage {
    // Max score per area is 50 (10 questions × 5 max per question)
    const maxScore = 50;
    return ((score / maxScore) * 100).round().clamp(0, 100);
  }
}

class RiasecCareer {
  final String href;
  final String code;
  final String title;
  final bool? brightOutlook;
  final String? fit;

  RiasecCareer({
    required this.href,
    required this.code,
    required this.title,
    this.brightOutlook,
    this.fit,
  });

  factory RiasecCareer.fromJson(Map<String, dynamic> json) {
    return RiasecCareer(
      href: json['href'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      brightOutlook: json['tags'] != null
          ? json['tags']['bright_outlook'] as bool?
          : null,
      fit: json['fit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'code': code,
      'title': title,
      'tags': brightOutlook != null ? {'bright_outlook': brightOutlook} : null,
      'fit': fit,
    };
  }
}

class RiasecResult {
  final List<RiasecInterestResult> interests;
  final List<RiasecCareer> careers;
  final DateTime completedAt;

  RiasecResult({
    required this.interests,
    required this.careers,
    required this.completedAt,
  });

  factory RiasecResult.fromJson(Map<String, dynamic> json) {
    return RiasecResult(
      interests: (json['interests'] as List<dynamic>)
          .map((interest) => RiasecInterestResult.fromJson(interest as Map<String, dynamic>))
          .toList(),
      careers: (json['careers'] as List<dynamic>)
          .map((career) => RiasecCareer.fromJson(career as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interests': interests.map((i) => i.toJson()).toList(),
      'careers': careers.map((c) => c.toJson()).toList(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  // Convert to RIASEC map format for AI match model
  Map<String, double> toRiasecMap() {
    final map = <String, double>{};
    for (var interest in interests) {
      // Normalize to 0.0-1.0 scale
      map[interest.code.substring(0, 1).toUpperCase()] = interest.percentage / 100.0;
    }
    return map;
  }

  // Get top 3 interest areas
  List<RiasecInterestResult> get topInterests {
    final sorted = List<RiasecInterestResult>.from(interests)
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(3).toList();
  }

  // Get best fit careers
  List<RiasecCareer> get bestFitCareers {
    return careers.where((c) => c.fit == 'Best').toList();
  }
}