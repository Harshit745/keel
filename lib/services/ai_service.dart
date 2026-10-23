import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/weekly_report.dart';
import '../models/build_log.dart';
import '../models/self_log.dart';

class AiService {
  static bool get _isConfigured => AppConstants.geminiApiKey.isNotEmpty;

  static String _extractJsonObject(String text) {
    final int start = text.indexOf('{');
    final int end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  static Future<Map<String, dynamic>> parseFounderLog(
    String userMessage,
    List<Map<String, dynamic>> conversationHistory, {
    String? contextSummary,
  }) async {
    if (!_isConfigured) {
      return <String, dynamic>{
        'error': 'config_error',
        'message':
            'AI is temporarily unavailable in this build. You can still use the rest of the app normally.',
      };
    }

    final String prompt =
        '''
You are the internal AI of an app called “Keel” — a private operating system for founders and builders.
Your role is NOT to behave like a generic assistant. You are a high-performance, brutally honest, clarity-driven thinking partner.

CORE OBJECTIVE:
Help the user move forward TODAY. Not tomorrow, not philosophically — today.

CONTEXT:
${contextSummary ?? "No context available."}

CONVERSATION HISTORY (Most recent first):
${conversationHistory.reversed.map((m) => "${m['role'].toUpperCase()}: ${m['content']}").join('\n')}

BEHAVIOR RULES:
1. Be concise but impactful. No long paragraphs unless absolutely necessary.
2. No generic motivation. No “you got this” or fluff.
3. Be slightly intense, but not toxic.
4. Prioritize clarity over politeness.
5. Default to actionable advice.
6. If user is stuck → simplify their next step.
7. If user is overworking → enforce recovery.
8. If user is consistent → reinforce identity, not praise.

RESPONSE STYLE:
- Start with a sharp observation.
- Then give 1–2 actionable steps.
- End with a short directive or question.

LOGIC GUIDELINES:
- If FounderScore < 40: Focus on recovery + smallest possible win.
- If Build low & Self high: Push execution.
- If Build high & Self low: Enforce slowdown.
- If both high: Push for leverage (systems, automation, scale).

INSTRUCTIONS:
1. If the user mentions health, build, or self data (sleep, tasks, revenue, etc.), EXTRACT it.
2. ALWAYS return valid JSON in the exact schema below. Regardless of the input, including simple greetings, you must return the FULL JSON with all fields populated. Never explain yourself outside the JSON.

CONSTRAINTS:
- Do NOT mention being an AI.
- Do NOT explain your reasoning unless asked.
- Do NOT give long educational answers.
- Do NOT change app features or suggest new ones.
- Only respond as the Keel AI.

JSON SCHEMA:
{
  "tasksShipped": 0,
  "talkedToUser": false,
  "movedNeedle": false,
  "revenueAdded": 0,
  "winOfDay": "",
  "sleepHours": 0,
  "energyLevel": 0,
  "moodRating": 0,
  "moneySpent": 0,
  "exercised": false,
  "ideas": [],
  "reply": "Your primary conversational response here following the RESPONSE STYLE Rules."
}

User Message: "$userMessage"
''';

    try {
      final http.Response response = await http.post(
        Uri.parse(
          '${AppConstants.geminiEndpoint}?key=${AppConstants.geminiApiKey}',
        ),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object>{
          'contents': <Map<String, Object>>[
            <String, Object>{
              'parts': <Map<String, String>>[
                <String, String>{'text': prompt},
              ],
            },
          ],
          'generationConfig': <String, Object>{
            'temperature': 0.1,
            'maxOutputTokens': 500,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String textResponse =
            responseJson['candidates'][0]['content']['parts'][0]['text']
                as String;
        final String jsonString = _extractJsonObject(textResponse);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to communicate with AI');
      }
    } catch (e) {
      if (e.toString().contains('Failed host lookup')) {
        return <String, dynamic>{
          'error': 'network_error',
          'message':
              'No internet connection. Please check your network and try again.',
        };
      }
      return <String, dynamic>{
        'error': 'parse_error',
        'message':
            "I couldn't quite catch that. Could you try phrasing it differently?",
      };
    }
  }

  static Future<String> generateWeeklyInsight({
    required int buildScore,
    required int selfScore,
    required int founderScore,
  }) async {
    if (!_isConfigured) {
      return 'AI insight is unavailable right now.';
    }

    final String prompt =
        '''
You are the Keel AI — a high-performance, brutally honest, clarity-driven thinking partner for founders.
The founder's weekly scores (0-100) are: 
- Build (progress): $buildScore
- Self (sustainability): $selfScore
- FounderScore (overall): $founderScore

Write a one-sentence (max 10 words), mildly provocative but encouraging insight for their weekly share card. 
No hashtags, no emojis.
Example 1: "Great build velocity, but sleep is not a luxury." (if build > self)
Example 2: "Sustainable, but are you actually shipping anything?" (if self > build)
Example 3: "Peak output. Keep the momentum going." (if both high)
''';

    try {
      final http.Response response = await http.post(
        Uri.parse(
          '${AppConstants.geminiEndpoint}?key=${AppConstants.geminiApiKey}',
        ),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object>{
          'contents': <Map<String, Object>>[
            <String, Object>{
              'parts': <Map<String, String>>[
                <String, String>{'text': prompt},
              ],
            },
          ],
          'generationConfig': <String, Object>{
            'temperature': 0.7,
            'maxOutputTokens': 50,
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String textResponse =
            responseJson['candidates'][0]['content']['parts'][0]['text']
                as String;
        return textResponse.trim().replaceAll('"', '');
      }
      return 'Keep showing up for yourself this week.';
    } catch (_) {
      return 'Keep showing up for yourself this week.';
    }
  }

  static Future<WeeklyReport> generateWeeklyReport(
    List<BuildLog> buildLogs,
    List<SelfLog> selfLogs,
  ) async {
    // Prepare data summary
    final double avgBuild = buildLogs.isEmpty
        ? 0.0
        : buildLogs
                  .map((BuildLog l) => l.buildScore)
                  .reduce((int a, int b) => a + b) /
              buildLogs.length;
    final double avgSelf = selfLogs.isEmpty
        ? 0.0
        : selfLogs
                  .map((SelfLog l) => l.selfScore)
                  .reduce((int a, int b) => a + b) /
              selfLogs.length;
    final double avgSleep = selfLogs.isEmpty
        ? 0.0
        : selfLogs
                  .map((SelfLog l) => l.sleepHours)
                  .reduce((double a, double b) => a + b) /
              selfLogs.length;
    final int tasksTotal = buildLogs.isEmpty
        ? 0
        : buildLogs
              .map((BuildLog l) => l.tasksShipped)
              .reduce((int a, int b) => a + b);
    final int userTalks = buildLogs
        .where((BuildLog l) => l.talkedToUser)
        .length;
    final int needleDays = buildLogs
        .where((BuildLog l) => l.movedNeedle)
        .length;
    final double avgFounder = (avgBuild * 0.6) + (avgSelf * 0.4);

    final String prompt =
        '''
You are the Keel AI — a high-performance, brutally honest thinking partner. Analyse this weekly performance report. Be direct, specific, and honest — not generic.

DATA FOR THIS WEEK:
- Average FounderScore: ${avgFounder.toStringAsFixed(1)}/100
- Average Build score: ${avgBuild.toStringAsFixed(1)}/100
- Average Self score: ${avgSelf.toStringAsFixed(1)}/100
- Total tasks shipped: $tasksTotal
- Days talked to a user: $userTalks/7
- Days moved the needle: $needleDays/7
- Average sleep: ${avgSleep.toStringAsFixed(1)} hours
- Number of days logged: ${buildLogs.length}/7

Respond ONLY with valid JSON, no markdown, no preamble:
{
  "insight": "2-3 sentence honest assessment of the week. Reference the actual numbers. Be direct.",
  "patterns": ["pattern 1 based on data", "pattern 2", "pattern 3"],
  "buildTrend": "up or down or stable",
  "selfTrend": "up or down or stable",
  "burnoutRisk": true or false,
  "burnoutReason": "specific reason if burnoutRisk is true, else null",
  "strongestPattern": "single clearest pattern from the week",
  "biggestRisk": "main risk holding the founder back",
  "biggestOpportunity": "main leverage point for next week",
  "nextWeekFocus": "one sentence focus for the coming week",
  "actions": [
    "specific action 1 for next week based on weakest area",
    "specific action 2",
    "specific action 3"
  ]
}
''';

    final DateTime now = DateTime.now();
    final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    if (!_isConfigured) {
      return WeeklyReport(
        insight:
            'AI report is unavailable in this build. Add GEMINI_API_KEY to enable weekly analysis.',
        patterns: <String>[
          'Build average: ${avgBuild.toStringAsFixed(0)}/100',
          'Self average: ${avgSelf.toStringAsFixed(0)}/100',
          'Days moved the needle: $needleDays/7',
        ],
        avgFounderScore: avgFounder,
        avgBuildScore: avgBuild,
        avgSelfScore: avgSelf,
        buildTrend: 'stable',
        selfTrend: 'stable',
        burnoutRisk: avgSelf < 40 || avgSleep < 6,
        burnoutReason: avgSelf < 40 || avgSleep < 6
            ? 'Low recovery metrics this week.'
            : null,
        strongestPattern: avgBuild >= avgSelf
            ? 'Execution stayed ahead of recovery.'
            : 'Recovery was stronger than execution.',
        biggestRisk: avgSelf < 40
            ? 'Low self-score will eventually flatten output.'
            : 'Inconsistent shipping is slowing momentum.',
        biggestOpportunity: userTalks < 2
            ? 'More user contact could raise build quality fast.'
            : 'Tighter daily clarity would compound quickly.',
        nextWeekFocus:
            'Keep the week simple: one meaningful build move and one recovery move each day.',
        actions: <String>[
          'Log each day so the weekly report has complete data.',
          'Raise the lowest-scoring area by one small step tomorrow.',
          'Review your lowest-scoring pattern and correct it early next week.',
        ],
        weekStart: weekStart,
        weekEnd: weekStart.add(const Duration(days: 6)),
      );
    }

    try {
      final http.Response response = await http.post(
        Uri.parse(
          '${AppConstants.geminiEndpoint}?key=${AppConstants.geminiApiKey}',
        ),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object>{
          'contents': <Map<String, Object>>[
            <String, Object>{
              'parts': <Map<String, String>>[
                <String, String>{'text': prompt},
              ],
            },
          ],
          'generationConfig': <String, Object>{
            'temperature': 0.1,
            'maxOutputTokens': 1000,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String textResponse =
            responseJson['candidates'][0]['content']['parts'][0]['text']
                as String;
        final String jsonString = _extractJsonObject(textResponse);
        final Map<String, dynamic> json =
            jsonDecode(jsonString) as Map<String, dynamic>;

        return WeeklyReport(
          insight: json['insight'] as String? ?? '',
          patterns: List<String>.from(
            json['patterns'] as Iterable<dynamic>? ?? <String>[],
          ),
          avgFounderScore: avgFounder,
          avgBuildScore: avgBuild,
          avgSelfScore: avgSelf,
          buildTrend: json['buildTrend'] as String? ?? 'stable',
          selfTrend: json['selfTrend'] as String? ?? 'stable',
          burnoutRisk: json['burnoutRisk'] as bool? ?? false,
          burnoutReason: json['burnoutReason'] as String?,
          strongestPattern:
              json['strongestPattern'] as String? ??
              'Execution and recovery are moving together.',
          biggestRisk:
              json['biggestRisk'] as String? ??
              'Inconsistent daily execution is limiting momentum.',
          biggestOpportunity:
              json['biggestOpportunity'] as String? ??
              'A tighter daily system could unlock a stronger week.',
          nextWeekFocus:
              json['nextWeekFocus'] as String? ??
              'Simplify the week around one meaningful priority.',
          actions: List<String>.from(
            json['actions'] as Iterable<dynamic>? ?? <String>[],
          ),
          weekStart: weekStart,
          weekEnd: weekStart.add(const Duration(days: 6)),
        );
      } else {
        throw Exception('Failed to communicate with AI');
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }
}
