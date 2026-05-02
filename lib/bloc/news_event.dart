abstract class NewsEvent {}

class LoadNews extends NewsEvent {
	final String? prompt;

	LoadNews({this.prompt});
}


