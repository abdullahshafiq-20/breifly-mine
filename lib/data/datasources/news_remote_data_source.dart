import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/news_item.dart';

class NewsRemoteDataSource {
  final http.Client client;

  NewsRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const String _curatedUrl =
      'https://news-curator-3494615909.us-central1.run.app/news';

  static const String _geminiBaseUrlDefault =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _geminiModelDefault = 'gemini-1.5-flash';

  Future<List<NewsItem>> fetchNews({String? prompt}) async {
    final trimmedPrompt = prompt?.trim();
    if (trimmedPrompt == null || trimmedPrompt.isEmpty) {
      return _fetchCuratedNews();
    }

    return _fetchGeminiNews(trimmedPrompt);
  }

  Future<List<NewsItem>> _fetchCuratedNews() async {
    final response = await client.get(Uri.parse(_curatedUrl));

    if (response.statusCode == 200) {
      return _parseCuratedNews(response.body);
    }

    throw Exception('Failed to load news (${response.statusCode})');
  }

  Future<List<NewsItem>> _fetchGeminiNews(String prompt) async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (geminiApiKey.isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env');
    }

    final geminiBaseUrl =
        dotenv.env['GEMINI_BASE_URL'] ?? _geminiBaseUrlDefault;
    final geminiModel = dotenv.env['GEMINI_MODEL'] ?? _geminiModelDefault;

    final uri = Uri.parse(
      '$geminiBaseUrl/$geminiModel:generateContent?key=$geminiApiKey',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': _buildPrompt(prompt),
              }
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 900,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini request failed (${response.statusCode})');
    }

    final text = _extractGeminiText(response.body);
    return _parseGeminiNews(text);
  }

  String _buildPrompt(String prompt) {
    return [
      'You are a news curator. Return JSON only.',
      'Create 6 to 10 concise items for the query below.',
      'Output schema: [{"headline":"...","body":"..."}].',
      'No markdown or extra commentary.',
      'Query: $prompt',
    ].join('\n');
  }

  String _extractGeminiText(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini response contained no candidates');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts != null && parts.isNotEmpty
        ? parts.first['text'] as String?
        : null;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini response contained no text');
    }

    return text.trim();
  }

  List<NewsItem> _parseGeminiNews(String rawText) {
    final jsonText = _stripCodeFences(rawText);
    final decoded = jsonDecode(jsonText);
    final items = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['items'] : null);

    if (items is! List) {
      throw Exception('Gemini response JSON was not a list');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => NewsItem(
            headline: _pickText(item, ['headline', 'title']) ?? 'News',
            body: _pickText(item, ['body', 'summary']) ?? 'Read more.',
          ),
        )
        .toList();
  }

  String _stripCodeFences(String rawText) {
    final fenceRegex = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final match = fenceRegex.firstMatch(rawText);
    return match?.group(1)?.trim() ?? rawText.trim();
  }

  String? _pickText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  List<NewsItem> _parseCuratedNews(String rawText) {
    final List<NewsItem> news = [];

    final lines =
        rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    for (final line in lines) {
      if (line.contains('**')) {
        final regex = RegExp(r'\*\*(.+?)\*\*');
        final match = regex.firstMatch(line);

        if (match != null) {
          final headline = match.group(1) ?? '';
          final body =
              line.replaceAll(regex, '').trim().replaceAll('*', '').trim();

          news.add(
            NewsItem(
              headline: headline,
              body: body.isEmpty
                  ? 'Read more about this tech trend.'
                  : body,
            ),
          );
        }
      }
    }

    return news;
  }
}


