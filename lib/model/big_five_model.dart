// lib/model/big_five_model.dart

class BigFiveChoice {
  final String text;
  final int score;
  final int color;

  BigFiveChoice({
    required this.text,
    required this.score,
    required this.color,
  });

  factory BigFiveChoice.fromJson(Map<String, dynamic> json) {
    return BigFiveChoice(
      text: json['text'] as String,
      score: json['score'] as int,
      color: json['color'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'score': score,
      'color': color,
    };
  }
}

class BigFiveQuestion {
  final String id;
  final String text;
  final String keyed;
  final String domain;
  final int facet;
  final int num;
  final List<BigFiveChoice> choices;

  BigFiveQuestion({
    required this.id,
    required this.text,
    required this.keyed,
    required this.domain,
    required this.facet,
    required this.num,
    required this.choices,
  });

  factory BigFiveQuestion.fromJson(Map<String, dynamic> json) {
    return BigFiveQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      keyed: json['keyed'] as String,
      domain: json['domain'] as String,
      facet: json['facet'] as int,
      num: json['num'] as int,
      choices: (json['choices'] as List<dynamic>)
          .map((choice) => BigFiveChoice.fromJson(choice as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'keyed': keyed,
      'domain': domain,
      'facet': facet,
      'num': num,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

class BigFiveAnswer {
  final String questionId;
  final String domain;
  final int facet;
  final int score;

  BigFiveAnswer({
    required this.questionId,
    required this.domain,
    required this.facet,
    required this.score,
  });

  factory BigFiveAnswer.fromJson(Map<String, dynamic> json) {
    return BigFiveAnswer(
      questionId: json['questionId'] as String,
      domain: json['domain'] as String,
      facet: json['facet'] as int,
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'domain': domain,
      'facet': facet,
      'score': score,
    };
  }
}

class BigFiveTestProgress {
  final List<BigFiveAnswer> answers;
  final int currentQuestionIndex;
  final DateTime lastUpdated;

  BigFiveTestProgress({
    required this.answers,
    required this.currentQuestionIndex,
    required this.lastUpdated,
  });

  factory BigFiveTestProgress.fromJson(Map<String, dynamic> json) {
    return BigFiveTestProgress(
      answers: (json['answers'] as List<dynamic>)
          .map((answer) => BigFiveAnswer.fromJson(answer as Map<String, dynamic>))
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
    return answers.length / 120.0; // 120 questions total
  }
}

class BigFiveFacetScore {
  final int facet;
  final String title;
  final String text;
  final int score;
  final int count;
  final String scoreText;

  BigFiveFacetScore({
    required this.facet,
    required this.title,
    required this.text,
    required this.score,
    required this.count,
    required this.scoreText,
  });

  factory BigFiveFacetScore.fromJson(Map<String, dynamic> json) {
    return BigFiveFacetScore(
      facet: json['facet'] as int,
      title: json['title'] as String,
      text: json['text'] as String,
      score: json['score'] as int,
      count: json['count'] as int,
      scoreText: json['scoreText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facet': facet,
      'title': title,
      'text': text,
      'score': score,
      'count': count,
      'scoreText': scoreText,
    };
  }
}

class BigFiveDomainResult {
  final String domain;
  final String title;
  final String shortDescription;
  final String description;
  final String scoreText;
  final int count;
  final int score;
  final List<BigFiveFacetScore> facets;
  final String text;

  BigFiveDomainResult({
    required this.domain,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.scoreText,
    required this.count,
    required this.score,
    required this.facets,
    required this.text,
  });

  factory BigFiveDomainResult.fromJson(Map<String, dynamic> json) {
    return BigFiveDomainResult(
      domain: json['domain'] as String,
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String,
      description: json['description'] as String,
      scoreText: json['scoreText'] as String,
      count: json['count'] as int,
      score: json['score'] as int,
      facets: (json['facets'] as List<dynamic>)
          .map((facet) => BigFiveFacetScore.fromJson(facet as Map<String, dynamic>))
          .toList(),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'title': title,
      'shortDescription': shortDescription,
      'description': description,
      'scoreText': scoreText,
      'count': count,
      'score': score,
      'facets': facets.map((f) => f.toJson()).toList(),
      'text': text,
    };
  }

  // Get percentage score (0-100)
  int get percentage {
    // Max possible score per question is 5, multiply by count
    final maxScore = count * 5;
    if (maxScore == 0) return 0;
    return ((score / maxScore) * 100).round();
  }
}

class BigFiveResult {
  final List<BigFiveDomainResult> domains;
  final DateTime completedAt;

  BigFiveResult({
    required this.domains,
    required this.completedAt,
  });

  factory BigFiveResult.fromJson(Map<String, dynamic> json) {
    return BigFiveResult(
      domains: (json['domains'] as List<dynamic>)
          .map((domain) => BigFiveDomainResult.fromJson(domain as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domains': domains.map((d) => d.toJson()).toList(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  // Convert to OCEAN map format for AI match model
  Map<String, double> toOceanMap() {
    final map = <String, double>{};
    for (var domain in domains) {
      // Normalize to 0.0-1.0 scale
      map[domain.domain] = domain.percentage / 100.0;
    }
    return map;
  }
}