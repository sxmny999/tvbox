/// 海洋CMS 接口地址配置
///
/// CMS 部署在开发电脑上（phpStudy，监听 0.0.0.0:8080），
/// 模拟器 / 真机与电脑不在同一个网络命名空间，必须通过电脑的局域网 IP 访问，
/// 因此默认地址使用 http://192.168.3.35:8080（电脑 IP，换网络后需同步修改）。
///
/// 其它环境可用编译期参数覆盖，例如桌面调试：
///   flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
class ApiConfig {
  ApiConfig._();

  /// 默认接口地址：开发电脑的局域网 IP
  static const String defaultBaseUrl = 'http://192.168.3.35:8080';

  /// 编译期覆盖地址（--dart-define=API_BASE_URL=...）
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// 实际使用的根地址
  static String get baseUrl =>
      _override.isNotEmpty ? _override : defaultBaseUrl;

  /// 接口入口（海洋CMS 统一 JSON 接口）
  static String get jsonApi => '$baseUrl/json.php';
}
