// lib/services/share_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/program.dart';
import '../model/university.dart';
import '../model/big_five_model.dart';
import '../model/mbti.dart';
import '../model/riasec_model.dart';
import '../model/ai_match_model.dart';
import '../utils/app_color.dart';

/// Enum for share types for analytics tracking
enum ShareType {
  university,
  program,
  bigFiveResult,
  mbtiResult,
  riasecResult,
  aiMatchResult,
  programList,
}

/// Share result model
class ShareResult {
  final bool success;
  final String? error;
  final ShareType type;

  ShareResult({
    required this.success,
    this.error,
    required this.type,
  });
}

/// Advanced Share Service with image generation and analytics
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static ShareService get instance => _instance;

  // Analytics callback (optional - can be connected to Firebase Analytics)
  Function(ShareType type, bool success)? onShareCompleted;

  /// Share University with optional image
  Future<ShareResult> shareUniversity({
    required UniversityModel university,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildUniversityMessage(university);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final result = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'Check out ${university.universityName}',
          );

          // Clean up temp file
          await imageFile.delete();

          final success = result.status == ShareResultStatus.success;
          _trackShare(ShareType.university, success);
          return ShareResult(success: success, type: ShareType.university);
        }
      }

      // Fallback to text-only share
      final result = await Share.share(
        message,
        subject: 'Check out ${university.universityName}',
      );

      final success = result.status == ShareResultStatus.success;
      _trackShare(ShareType.university, success);
      return ShareResult(success: success, type: ShareType.university);
    } catch (e) {
      debugPrint('❌ Share university error: $e');
      _trackShare(ShareType.university, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.university,
      );
    }
  }

  /// Share Program with optional image
  Future<ShareResult> shareProgram({
    required ProgramModel program,
    String? universityName,
    String? branchLocation,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildProgramMessage(
        program,
        universityName: universityName,
        branchLocation: branchLocation,
      );

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final result = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: program.programName,
          );

          await imageFile.delete();

          final success = result.status == ShareResultStatus.success;
          _trackShare(ShareType.program, success);
          return ShareResult(success: success, type: ShareType.program);
        }
      }

      final result = await Share.share(
        message,
        subject: 'Check out this program: ${program.programName}',
      );

      final success = result.status == ShareResultStatus.success;
      _trackShare(ShareType.program, success);
      return ShareResult(success: success, type: ShareType.program);
    } catch (e) {
      debugPrint('❌ Share program error: $e');
      _trackShare(ShareType.program, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.program,
      );
    }
  }

  /// Share Big Five Result with optional image
  Future<ShareResult> shareBigFiveResult({
    required BigFiveResult result,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildBigFiveMessage(result);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final shareResult = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'My Big Five Personality Results',
          );

          await imageFile.delete();

          final success = shareResult.status == ShareResultStatus.success;
          _trackShare(ShareType.bigFiveResult, success);
          return ShareResult(success: success, type: ShareType.bigFiveResult);
        }
      }

      final shareResult = await Share.share(
        message,
        subject: 'My Big Five Personality Results',
      );

      final success = shareResult.status == ShareResultStatus.success;
      _trackShare(ShareType.bigFiveResult, success);
      return ShareResult(success: success, type: ShareType.bigFiveResult);
    } catch (e) {
      debugPrint('❌ Share Big Five error: $e');
      _trackShare(ShareType.bigFiveResult, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.bigFiveResult,
      );
    }
  }

  /// Share MBTI Result with optional image
  Future<ShareResult> shareMBTIResult({
    required MBTIResult result,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildMBTIMessage(result);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final shareResult = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'My MBTI Type: ${result.fullCode}',
          );

          await imageFile.delete();

          final success = shareResult.status == ShareResultStatus.success;
          _trackShare(ShareType.mbtiResult, success);
          return ShareResult(success: success, type: ShareType.mbtiResult);
        }
      }

      final shareResult = await Share.share(
        message,
        subject: 'My MBTI Type: ${result.fullCode}',
      );

      final success = shareResult.status == ShareResultStatus.success;
      _trackShare(ShareType.mbtiResult, success);
      return ShareResult(success: success, type: ShareType.mbtiResult);
    } catch (e) {
      debugPrint('❌ Share MBTI error: $e');
      _trackShare(ShareType.mbtiResult, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.mbtiResult,
      );
    }
  }

  /// Share RIASEC Result with optional image
  Future<ShareResult> shareRiasecResult({
    required RiasecResult result,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildRiasecMessage(result);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final shareResult = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'My RIASEC Career Interests',
          );

          await imageFile.delete();

          final success = shareResult.status == ShareResultStatus.success;
          _trackShare(ShareType.riasecResult, success);
          return ShareResult(success: success, type: ShareType.riasecResult);
        }
      }

      final shareResult = await Share.share(
        message,
        subject: 'My RIASEC Career Interests',
      );

      final success = shareResult.status == ShareResultStatus.success;
      _trackShare(ShareType.riasecResult, success);
      return ShareResult(success: success, type: ShareType.riasecResult);
    } catch (e) {
      debugPrint('❌ Share RIASEC error: $e');
      _trackShare(ShareType.riasecResult, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.riasecResult,
      );
    }
  }

  /// Share AI Match Results with optional image
  Future<ShareResult> shareAIMatchResults({
    required List<RecommendedSubjectArea> recommendations,
    required int programCount,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildAIMatchMessage(recommendations, programCount);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final shareResult = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'My PathWise AI Program Matches',
          );

          await imageFile.delete();

          final success = shareResult.status == ShareResultStatus.success;
          _trackShare(ShareType.aiMatchResult, success);
          return ShareResult(success: success, type: ShareType.aiMatchResult);
        }
      }

      final shareResult = await Share.share(
        message,
        subject: 'My PathWise AI Program Matches',
      );

      final success = shareResult.status == ShareResultStatus.success;
      _trackShare(ShareType.aiMatchResult, success);
      return ShareResult(success: success, type: ShareType.aiMatchResult);
    } catch (e) {
      debugPrint('❌ Share AI Match error: $e');
      _trackShare(ShareType.aiMatchResult, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.aiMatchResult,
      );
    }
  }

  /// Share Matched Programs
  Future<ShareResult> shareMatchedPrograms({
    required List<ProgramModel> programs,
    required List<RecommendedSubjectArea> recommendations,
    GlobalKey? screenshotKey,
    BuildContext? context,
  }) async {
    try {
      final message = _buildMatchedProgramsMessage(programs, recommendations);

      if (screenshotKey != null && context != null) {
        final imageFile = await _captureAndSaveScreenshot(screenshotKey);
        if (imageFile != null) {
          final shareResult = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: message,
            subject: 'My PathWise Program Matches',
          );

          await imageFile.delete();

          final success = shareResult.status == ShareResultStatus.success;
          _trackShare(ShareType.programList, success);
          return ShareResult(success: success, type: ShareType.programList);
        }
      }

      final shareResult = await Share.share(
        message,
        subject: 'My PathWise Program Matches',
      );

      final success = shareResult.status == ShareResultStatus.success;
      _trackShare(ShareType.programList, success);
      return ShareResult(success: success, type: ShareType.programList);
    } catch (e) {
      debugPrint('❌ Share matched programs error: $e');
      _trackShare(ShareType.programList, false);
      return ShareResult(
        success: false,
        error: e.toString(),
        type: ShareType.programList,
      );
    }
  }

  // ============== Private Helper Methods ==============

  /// Capture screenshot from GlobalKey
  Future<File?> _captureAndSaveScreenshot(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      debugPrint('❌ Screenshot capture error: $e');
      return null;
    }
  }

  /// Track share analytics
  void _trackShare(ShareType type, bool success) {
    debugPrint('📊 Share Analytics: ${type.name} - ${success ? "Success" : "Failed"}');
    onShareCompleted?.call(type, success);
  }

  // ============== Message Builders ==============

  String _buildUniversityMessage(UniversityModel university) {
    final buffer = StringBuffer();

    buffer.writeln('🎓 ${university.universityName}');
    buffer.writeln('');

    if (university.minRanking != null) {
      if (university.maxRanking == null || university.minRanking == university.maxRanking) {
        buffer.writeln('🏆 QS World Ranking: #${university.minRanking}');
      } else {
        buffer.writeln('🏆 QS World Ranking: #${university.minRanking} - #${university.maxRanking}');
      }
    }

    buffer.writeln('🏛️ ${university.institutionType} Institution');

    if (university.branches.isNotEmpty) {
      final branch = university.branches.first;
      buffer.writeln('📍 ${branch.city.isNotEmpty ? "${branch.city}, " : ""}${branch.country}');

      if (university.branches.length > 1) {
        buffer.writeln('   +${university.branches.length - 1} more ${university.branches.length - 1 == 1 ? "campus" : "campuses"}');
      }
    }

    if (university.totalStudents != null) {
      buffer.writeln('👥 ${_formatNumber(university.totalStudents!)} students');
    }

    if (university.programCount > 0) {
      buffer.writeln('📚 ${university.programCount}+ programs');
    }

    buffer.writeln('');
    buffer.writeln('💡 Discover more universities on PathWise');
    buffer.writeln('   Find your perfect educational match!');
    buffer.writeln('');
    buffer.writeln('🔗 ${university.universityUrl}');

    return buffer.toString();
  }

  String _buildProgramMessage(
      ProgramModel program, {
        String? universityName,
        String? branchLocation,
      }) {
    final buffer = StringBuffer();

    buffer.writeln('📖 ${program.programName}');
    buffer.writeln('');

    if (universityName != null) {
      buffer.writeln('🏛️ $universityName');
    }

    if (branchLocation != null) {
      buffer.writeln('📍 $branchLocation');
    }

    if (program.studyLevel != null) {
      buffer.writeln('🎓 ${program.studyLevel} Program');
    }

    if (program.subjectArea != null) {
      buffer.write('📚 ${program.subjectArea}');
      if (program.hasSubjectRanking) {
        buffer.write(' | ${program.formattedSubjectRanking}');
        if (program.isTopRanked) {
          buffer.write(' 🏆');
        }
      }
      buffer.writeln('');
    }

    if (program.durationMonths != null) {
      buffer.writeln('⏱️ ${program.formattedDuration}');
    }

    if (program.studyMode != null) {
      buffer.writeln('🏫 ${program.studyMode}');
    }

    if (program.intakePeriod.isNotEmpty) {
      buffer.writeln('📅 Intakes: ${program.intakePeriod.join(", ")}');
    }

    if (program.minInternationalTuitionFee != null) {
      buffer.writeln('💰 From ${program.minInternationalTuitionFee} (Intl)');
    }

    buffer.writeln('');
    buffer.writeln('🎯 Find your perfect program with PathWise AI');
    buffer.writeln('   Get personalized recommendations today!');
    buffer.writeln('');
    buffer.writeln('🔗 ${program.programUrl}');

    return buffer.toString();
  }

  String _buildBigFiveMessage(BigFiveResult result) {
    final buffer = StringBuffer();

    buffer.writeln('🧠 My Big Five Personality Profile');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    final sortedDomains = List<BigFiveDomainResult>.from(result.domains)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    for (int i = 0; i < sortedDomains.length; i++) {
      final domain = sortedDomains[i];
      final emoji = _getBigFiveEmoji(domain.domain);
      final bar = _createProgressBar(domain.percentage);

      buffer.writeln('$emoji ${domain.title}');
      buffer.writeln('   $bar ${domain.percentage}%');
      buffer.writeln('   ${domain.scoreText}');
      if (i < sortedDomains.length - 1) buffer.writeln('');
    }

    buffer.writeln('');
    buffer.writeln('📅 Completed: ${_formatDate(result.completedAt)}');
    buffer.writeln('');
    buffer.writeln('🎯 Discover your personality with PathWise');
    buffer.writeln('   Take the Big Five assessment today!');

    return buffer.toString();
  }

  String _buildMBTIMessage(MBTIResult result) {
    final buffer = StringBuffer();

    buffer.writeln('🎭 My MBTI Personality Type');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('✨ ${result.fullCode} - "${result.niceName}"');
    buffer.writeln('');
    buffer.writeln('📝 ${result.snippet}');
    buffer.writeln('');
    buffer.writeln('My Personality Dimensions:');

    for (var trait in result.traits) {
      final bar = _createProgressBar(trait.pct);
      buffer.writeln('• ${trait.trait}');
      buffer.writeln('  $bar ${trait.pct}%');
    }

    buffer.writeln('');
    buffer.writeln('🎯 Discover your MBTI type on PathWise');
    buffer.writeln('   Take the 16Personalities assessment!');

    return buffer.toString();
  }

  String _buildRiasecMessage(RiasecResult result) {
    final buffer = StringBuffer();

    buffer.writeln('💼 My RIASEC Career Interest Profile');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    final topInterests = result.topInterests;
    buffer.writeln('Top 3 Interest Areas:');
    for (int i = 0; i < topInterests.length && i < 3; i++) {
      final interest = topInterests[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';
      final bar = _createProgressBar(interest.percentage);

      buffer.writeln('$medal ${interest.title}');
      buffer.writeln('   $bar ${interest.percentage}%');
      if (i < topInterests.length - 1) buffer.writeln('');
    }

    buffer.writeln('');

    final bestFitCareers = result.bestFitCareers;
    if (bestFitCareers.isNotEmpty) {
      buffer.writeln('🎯 Best Fit Careers:');
      for (int i = 0; i < bestFitCareers.length && i < 5; i++) {
        final career = bestFitCareers[i];
        buffer.write('   ${i + 1}. ${career.title}');
        if (career.brightOutlook == true) buffer.write(' ⭐');
        buffer.writeln('');
      }
      buffer.writeln('');
    }

    buffer.writeln('📅 Completed: ${_formatDate(result.completedAt)}');
    buffer.writeln('');
    buffer.writeln('🎯 Find your career path with PathWise');
    buffer.writeln('   Take the RIASEC assessment today!');

    return buffer.toString();
  }

  String _buildAIMatchMessage(
      List<RecommendedSubjectArea> recommendations,
      int programCount,
      ) {
    final buffer = StringBuffer();

    buffer.writeln('🤖 My PathWise AI Program Matches');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('✨ AI matched me with $programCount perfect');
    buffer.writeln('   ${programCount == 1 ? "program" : "programs"} based on my profile!');
    buffer.writeln('');
    buffer.writeln('🎯 Top Subject Area Matches:');

    for (int i = 0; i < recommendations.length && i < 5; i++) {
      final rec = recommendations[i];
      final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '#';
      final matchPercent = (rec.matchScore * 100).toStringAsFixed(0);

      buffer.writeln('');
      buffer.writeln('$medal ${rec.subjectArea}');
      buffer.writeln('- Match Score: $matchPercent%');
      // buffer.writeln('- ${rec.reason}');

      if (rec.careerPaths.isNotEmpty) {
        buffer.writeln('- Careers: ${rec.careerPaths.take(3).join(", ")}');
      }
    }

    buffer.writeln('');
    buffer.writeln('🎓 Get AI-powered recommendations on PathWise');
    buffer.writeln('🤖 Find your perfect educational path today!');

    return buffer.toString();
  }

  String _buildMatchedProgramsMessage(
      List<ProgramModel> programs,
      List<RecommendedSubjectArea> recommendations,
      ) {
    final buffer = StringBuffer();

    buffer.writeln('🎓 My PathWise Program Matches');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('✨ ${programs.length} programs matched to my profile!');
    buffer.writeln('');

    final programsBySubject = <String, List<ProgramModel>>{};
    for (var program in programs) {
      if (program.subjectArea != null) {
        programsBySubject.putIfAbsent(program.subjectArea!, () => []).add(program);
      }
    }

    int count = 0;
    for (var rec in recommendations) {
      if (count >= 3) break;

      final matchingPrograms = programsBySubject[rec.subjectArea] ?? [];
      if (matchingPrograms.isNotEmpty) {
        final matchPercent = (rec.matchScore * 100).toStringAsFixed(0);

        buffer.writeln('${rec.subjectArea} ($matchPercent% match)');

        for (int i = 0; i < matchingPrograms.length && i < 3; i++) {
          final program = matchingPrograms[i];
          buffer.write('  ${i + 1}. ${program.programName}');
          if (program.hasSubjectRanking && program.isTopRanked) {
            buffer.write(' 🏆');
          }
          buffer.writeln('');

          if (program.studyLevel != null) {
            buffer.write('     ${program.studyLevel}');
            if (program.hasSubjectRanking) {
              buffer.write(' | ${program.formattedSubjectRanking}');
            }
            buffer.writeln('');
          }
        }

        if (matchingPrograms.length > 3) {
          buffer.writeln('  ... +${matchingPrograms.length - 3} more');
        }

        buffer.writeln('');
        count++;
      }
    }

    buffer.writeln('🎯 Find your perfect program on PathWise');
    buffer.writeln('   AI-powered recommendations just for you!');

    return buffer.toString();
  }

  // ============== Utility Methods ==============

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _getBigFiveEmoji(String domain) {
    switch (domain.toUpperCase()) {
      case 'O': return '💡';
      case 'C': return '✅';
      case 'E': return '🎉';
      case 'A': return '❤️';
      case 'N': return '😌';
      default: return '⭐';
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _createProgressBar(int percentage) {
    const barLength = 10;
    final filled = (percentage / 10).round();
    final empty = barLength - filled;
    return '[${'█' * filled}${'░' * empty}]';
  }
}