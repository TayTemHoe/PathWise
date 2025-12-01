// lib/model/mbti_test_model.dart

class MBTIQuestion {
  final String id;
  final String text;
  final List<MBTIOption> options;

  MBTIQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  factory MBTIQuestion.fromJson(Map<String, dynamic> json) {
    return MBTIQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      options: (json['options'] as List<dynamic>)
          .map((option) => MBTIOption.fromJson(option as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class MBTIOption {
  final String text;
  final int value;

  MBTIOption({
    required this.text,
    required this.value,
  });

  factory MBTIOption.fromJson(Map<String, dynamic> json) {
    return MBTIOption(
      text: json['text'] as String,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'value': value,
    };
  }
}

class MBTIAnswer {
  final String questionId;
  final int value;

  MBTIAnswer({
    required this.questionId,
    required this.value,
  });

  factory MBTIAnswer.fromJson(Map<String, dynamic> json) {
    return MBTIAnswer(
      questionId: json['id'] as String,
      value: json['value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': questionId,
      'value': value,
    };
  }
}

class MBTITestProgress {
  final List<MBTIAnswer> answers;
  final int currentQuestionIndex;
  final DateTime lastUpdated;

  MBTITestProgress({
    required this.answers,
    required this.currentQuestionIndex,
    required this.lastUpdated,
  });

  factory MBTITestProgress.fromJson(Map<String, dynamic> json) {
    return MBTITestProgress(
      answers: (json['answers'] as List<dynamic>)
          .map((answer) => MBTIAnswer.fromJson(answer as Map<String, dynamic>))
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
    return answers.length / 60.0; // 16Personalities has ~60 questions
  }
}

class MBTIResult {
  final String niceName;
  final String fullCode;
  final String avatarSrc;
  final String avatarAlt;
  final String avatarSrcStatic;
  final String snippet;
  final List<String> scales;
  final List<MBTITrait> traits;

  MBTIResult({
    required this.niceName,
    required this.fullCode,
    required this.avatarSrc,
    required this.avatarAlt,
    required this.avatarSrcStatic,
    required this.snippet,
    required this.scales,
    required this.traits,
  });

  factory MBTIResult.fromJson(Map<String, dynamic> json) {
    return MBTIResult(
      niceName: json['niceName'] as String,
      fullCode: json['fullCode'] as String,
      avatarSrc: json['avatarSrc'] as String,
      avatarAlt: json['avatarAlt'] as String,
      avatarSrcStatic: json['avatarSrcStatic'] as String,
      snippet: json['snippet'] as String,
      scales: (json['scales'] as List<dynamic>).map((s) => s as String).toList(),
      traits: (json['traits'] as List<dynamic>)
          .map((trait) => MBTITrait.fromJson(trait as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'niceName': niceName,
      'fullCode': fullCode,
      'avatarSrc': avatarSrc,
      'avatarAlt': avatarAlt,
      'avatarSrcStatic': avatarSrcStatic,
      'snippet': snippet,
      'scales': scales,
      'traits': traits.map((t) => t.toJson()).toList(),
    };
  }
}

class MBTITrait {
  final String key;
  final String label;
  final String color;
  final int score;
  final int pct;
  final String trait;
  final String link;
  final bool reverse;
  final String description;
  final String snippet;
  final String imageAlt;
  final String imageSrc;

  MBTITrait({
    required this.key,
    required this.label,
    required this.color,
    required this.score,
    required this.pct,
    required this.trait,
    required this.link,
    required this.reverse,
    required this.description,
    required this.snippet,
    required this.imageAlt,
    required this.imageSrc,
  });

  factory MBTITrait.fromJson(Map<String, dynamic> json) {
    return MBTITrait(
      key: json['key'] as String,
      label: json['label'] as String,
      color: json['color'] as String,
      score: json['score'] as int,
      pct: json['pct'] as int,
      trait: json['trait'] as String,
      link: json['link'] as String,
      reverse: json['reverse'] as bool,
      description: json['description'] as String,
      snippet: json['snippet'] as String,
      imageAlt: json['imageAlt'] as String,
      imageSrc: json['imageSrc'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'color': color,
      'score': score,
      'pct': pct,
      'trait': trait,
      'link': link,
      'reverse': reverse,
      'description': description,
      'snippet': snippet,
      'imageAlt': imageAlt,
      'imageSrc': imageSrc,
    };
  }
}