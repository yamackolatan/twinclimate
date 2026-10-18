import 'dart:io';

/// Dart ignores HTTPS_PROXY by default; cloud sandboxes need it (and
/// their CA bundle) to reach the internet.
class _EnvProxyOverrides extends HttpOverrides {
  _EnvProxyOverrides(this.caBundle);

  final String? caBundle;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final security = SecurityContext(withTrustedRoots: true);
    if (caBundle != null) security.setTrustedCertificates(caBundle!);
    return super.createHttpClient(security)
      ..findProxy = HttpClient.findProxyFromEnvironment;
  }
}

/// Routes Dart's HTTP through the sandbox proxy when one is configured.
void useSandboxProxy() {
  if (Platform.environment['HTTPS_PROXY'] == null) return;
  const sandboxBundle = '/root/.ccr/ca-bundle.crt';
  HttpOverrides.global = _EnvProxyOverrides(
    File(sandboxBundle).existsSync() ? sandboxBundle : null,
  );
}
