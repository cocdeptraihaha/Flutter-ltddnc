import 'package:dio/dio.dart';

import 'models/admin_models.dart';

class BookAdminService {
  BookAdminService(this._dio);

  final Dio _dio;

  Future<PageResult<BookListItem>> listBooks({
    int page = 1,
    int size = 20,
    String? q,
    int? categoryId,
    bool includeDeleted = false,
    String? status,
    String sort = 'id',
    String order = 'desc',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/books/admin/all',
      queryParameters: <String, dynamic>{
        'page': page,
        'size': size,
        if (q != null && q.isNotEmpty) 'q': q,
        if (categoryId != null) 'category_id': categoryId,
        'include_deleted': includeDeleted,
        if (status != null) 'status': status,
        'sort': sort,
        'order': order,
      },
    );
    return parseBookPage(res.data!);
  }

  Future<List<BookListItem>> lowStock({int threshold = 5, int limit = 50}) async {
    final res = await _dio.get<List<dynamic>>(
      '/books/admin/low-stock',
      queryParameters: {'threshold': threshold, 'limit': limit},
    );
    return (res.data ?? [])
        .map((e) => BookListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createBook(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/books/', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>('/books/$id', data: body);
    return res.data!;
  }

  Future<void> softDeleteBook(int id) async {
    await _dio.delete<void>('/books/$id');
  }

  Future<Map<String, dynamic>> restoreBook(int id) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/books/$id/restore');
    return res.data!;
  }

  Future<Map<String, dynamic>> putCategories(int bookId, List<int> categoryIds) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/books/$bookId/categories',
      data: {'category_ids': categoryIds},
    );
    return res.data!;
  }

  Future<void> uploadBookDetailImage(int detailId, String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await _dio.post<void>(
      '/upload/book-detail/$detailId/image',
      data: form,
    );
  }
}
