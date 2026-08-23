enum WebNavigationDecision { internal, external, rejected }

final class WebNavigationPolicy {
  const WebNavigationPolicy({required this.allowedOrigins});
  final Set<String> allowedOrigins;

  WebNavigationDecision decide(Uri uri) {
    if (uri.scheme != 'https') return WebNavigationDecision.rejected;
    return allowedOrigins.contains(uri.origin)
        ? WebNavigationDecision.internal
        : WebNavigationDecision.external;
  }
}
