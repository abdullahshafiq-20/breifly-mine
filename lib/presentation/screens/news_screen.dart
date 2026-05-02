import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/news_bloc.dart';
import '../../bloc/news_event.dart';
import '../../bloc/news_state.dart';
import '../widgets/news_card.dart';
import '../widgets/share_daily_brief_sheet.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<NewsBloc>().add(LoadNews());
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final prompt = _promptController.text.trim();
    context.read<NewsBloc>().add(
          LoadNews(prompt: prompt.isEmpty ? null : prompt),
        );
    FocusScope.of(context).unfocus();
  }

  Widget _buildPromptField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _promptController,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submitPrompt(),
        decoration: InputDecoration(
          hintText: 'Ask for news (e.g., AI chips this week)',
          filled: true,
          fillColor: Colors.grey.shade900.withAlpha(160),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: _submitPrompt,
            icon: const Icon(Icons.arrow_forward),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChips(List<Map<String, dynamic>> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categories.length, (i) {
            final category = categories[i];
            final leftPadding = i == 0 ? 16.0 : 16.0;
            return Padding(
              padding: EdgeInsets.only(left: leftPadding),
              child: Chip(
                label: Text(
                  category['label'],
                  style: TextStyle(
                    color: category['textColor'] ?? Colors.white,
                  ),
                ),
                backgroundColor: category['color'],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: 'Briefly',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            children: const <TextSpan>[
              TextSpan(
                text: '.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.lime,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
          CircleAvatar(child: Icon(Icons.person_2_outlined)),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          final newsCount = state is NewsLoaded ? state.news.length : 5;
          return FloatingActionButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                isDismissible: false,
                builder: (BuildContext context) {
                  return ShareDailyBriefSheet(newsCount: newsCount);
                },
              );
            },
            shape: const CircleBorder(),
            child: const Icon(Icons.share_outlined),
          );
        },
      ),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          final List<Map<String, dynamic>> categories = [
            {
              'label': 'Tech',
              'color': Colors.lime,
              'textColor': Colors.black,
            },
            {'label': 'Sports'},
            {'label': 'Politics'},
            {'label': 'Crypto'},
            {'label': 'Design'},
          ];

          if (state is NewsLoading || state is NewsInitial) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildPromptField(),
                _buildChips(categories),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (state is NewsError) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildPromptField(),
                _buildChips(categories),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${state.message}'),
                ),
              ],
            );
          }

          if (state is NewsLoaded) {
            final news = state.news;

            return RefreshIndicator(
              onRefresh: () async {
                // Simply dispatch the LoadNews event, just like in initState
                context.read<NewsBloc>().add(LoadNews());
              },
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: news.length + 3, // prompt, chips row, spacing
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildPromptField();
                  } else if (index == 1) {
                    // Chips row under the prompt
                    return _buildChips(categories);
                  } else if (index == 2) {
                    // Spacing after chips row
                    return const SizedBox(height: 8);
                  } else {
                    // News cards
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: NewsCard(item: news[index - 3]),
                    );
                  }
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
