class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    final apiBaseUrl = (configuredUrl.isEmpty
            ? 'https://pizzariacampy.onrender.com/api/v1'
            : configuredUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    return AppConfig(
      apiBaseUrl: apiBaseUrl,
    );
  }

  final String apiBaseUrl;
}
