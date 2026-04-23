import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api_client.dart';

/// Tải endpoint trả về bytes (CSV) rồi mở / chia sẻ.
Future<void> downloadAndShareCsv(
  Dio dio, {
  required String path,
  Map<String, dynamic>? queryParameters,
  String fileName = 'export.csv',
}) async {
  final res = await dio.get<List<int>>(
    path,
    queryParameters: queryParameters,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = res.data;
  if (bytes == null || bytes.isEmpty) {
    throw ApiException('File rỗng');
  }
  final dir = await getTemporaryDirectory();
  final fp = '${dir.path}/$fileName';
  await File(fp).writeAsBytes(bytes);
  await Share.shareXFiles([XFile(fp)], subject: fileName);
}
