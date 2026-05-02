import '../datasources/news_remote_data_source.dart';
import '../models/news_item.dart';

class NewsRepository {
  final NewsRemoteDataSource remoteDataSource;

  NewsRepository({required this.remoteDataSource});

  Future<List<NewsItem>> getNews({String? prompt}) {
    return remoteDataSource.fetchNews(prompt: prompt);
  }
}


