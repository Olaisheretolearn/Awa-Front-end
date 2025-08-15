
import '../api/client.dart';

String absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${ApiClient.origin}$path';
}
