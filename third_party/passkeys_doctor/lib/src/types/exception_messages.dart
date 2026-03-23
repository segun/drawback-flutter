class ExceptionInfo {
  const ExceptionInfo({
    required this.title,
    required this.description,
    required this.platforms,
    required this.suggestions,
  });

  final String title;
  final String description;
  final List<String> platforms;
  final List<String> suggestions;
}

const Map<String, ExceptionInfo> exceptionInfos = <String, ExceptionInfo>{};
