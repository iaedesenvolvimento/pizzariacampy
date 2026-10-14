class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      apiBaseUrl: configuredUrl.isEmpty
          ? 'https://pizzariacampy.onrender.com/api/v1'
          : configuredUrl,
    );
  }

  final String apiBaseUrl;
}
