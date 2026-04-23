// ignore_for_file: public_member_api_docs

double? _numToDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

class DashboardSummary {
  DashboardSummary({
    required this.revenue,
    required this.orderCount,
    required this.aov,
    required this.newUserCount,
    required this.lowStockCount,
    required this.pendingOrderCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        revenue: _numToDouble(j['revenue']) ?? 0,
        orderCount: j['order_count'] as int? ?? 0,
        aov: _numToDouble(j['aov']) ?? 0,
        newUserCount: j['new_user_count'] as int? ?? 0,
        lowStockCount: j['low_stock_count'] as int? ?? 0,
        pendingOrderCount: j['pending_order_count'] as int? ?? 0,
      );

  final double revenue;
  final int orderCount;
  final double aov;
  final int newUserCount;
  final int lowStockCount;
  final int pendingOrderCount;
}

class TimeseriesPoint {
  TimeseriesPoint({
    required this.period,
    required this.orderCount,
    required this.revenue,
  });

  factory TimeseriesPoint.fromJson(Map<String, dynamic> j) => TimeseriesPoint(
        period: j['period']?.toString() ?? '',
        orderCount: j['order_count'] as int? ?? 0,
        revenue: _numToDouble(j['revenue']) ?? 0,
      );

  final String period;
  final int orderCount;
  final double revenue;
}

class TopBookRow {
  TopBookRow({
    required this.bookId,
    this.title,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopBookRow.fromJson(Map<String, dynamic> j) => TopBookRow(
        bookId: j['book_id'] as int,
        title: j['title'] as String?,
        quantitySold: j['quantity_sold'] as int? ?? 0,
        revenue: _numToDouble(j['revenue']) ?? 0,
      );

  final int bookId;
  final String? title;
  final int quantitySold;
  final double revenue;
}

class CategoryRevenueRow {
  CategoryRevenueRow({
    required this.categoryId,
    this.categoryName,
    required this.revenue,
    required this.orderCount,
  });

  factory CategoryRevenueRow.fromJson(Map<String, dynamic> j) => CategoryRevenueRow(
        categoryId: j['category_id'] as int,
        categoryName: j['category_name'] as String?,
        revenue: _numToDouble(j['revenue']) ?? 0,
        orderCount: j['order_count'] as int? ?? 0,
      );

  final int categoryId;
  final String? categoryName;
  final double revenue;
  final int orderCount;
}

class TopCustomerRow {
  TopCustomerRow({
    required this.userId,
    this.fullName,
    this.email,
    required this.orderCount,
    required this.totalSpent,
  });

  factory TopCustomerRow.fromJson(Map<String, dynamic> j) => TopCustomerRow(
        userId: j['user_id'] as int,
        fullName: j['full_name'] as String?,
        email: j['email'] as String?,
        orderCount: j['order_count'] as int? ?? 0,
        totalSpent: _numToDouble(j['total_spent']) ?? 0,
      );

  final int userId;
  final String? fullName;
  final String? email;
  final int orderCount;
  final double totalSpent;
}

class OrderStatusBreakdownRow {
  OrderStatusBreakdownRow({
    required this.status,
    required this.count,
    required this.revenue,
  });

  factory OrderStatusBreakdownRow.fromJson(Map<String, dynamic> j) =>
      OrderStatusBreakdownRow(
        status: j['status']?.toString() ?? '',
        count: j['count'] as int? ?? 0,
        revenue: _numToDouble(j['revenue']) ?? 0,
      );

  final String status;
  final int count;
  final double revenue;
}

class CancelRatePoint {
  CancelRatePoint({
    required this.period,
    required this.totalOrders,
    required this.cancelledCount,
    required this.cancelRate,
  });

  factory CancelRatePoint.fromJson(Map<String, dynamic> j) => CancelRatePoint(
        period: j['period']?.toString() ?? '',
        totalOrders: j['total_orders'] as int? ?? 0,
        cancelledCount: j['cancelled_count'] as int? ?? 0,
        cancelRate: _numToDouble(j['cancel_rate']) ?? 0,
      );

  final String period;
  final int totalOrders;
  final int cancelledCount;
  final double cancelRate;
}

class MoneyBucket {
  MoneyBucket({required this.count, required this.total});

  factory MoneyBucket.fromJson(Map<String, dynamic> j) => MoneyBucket(
        count: j['count'] as int? ?? 0,
        total: _numToDouble(j['total']) ?? 0,
      );

  final int count;
  final double total;
}

class OrderRevenueStats {
  OrderRevenueStats({
    required this.pendingConfirm,
    required this.shipping,
    required this.delivered,
    required this.cancelled,
    required this.totalSpent,
  });

  factory OrderRevenueStats.fromJson(Map<String, dynamic> j) =>
      OrderRevenueStats(
        pendingConfirm:
            MoneyBucket.fromJson(j['pending_confirm'] as Map<String, dynamic>),
        shipping: MoneyBucket.fromJson(j['shipping'] as Map<String, dynamic>),
        delivered:
            MoneyBucket.fromJson(j['delivered'] as Map<String, dynamic>),
        cancelled:
            MoneyBucket.fromJson(j['cancelled'] as Map<String, dynamic>),
        totalSpent: _numToDouble(j['total_spent']) ?? 0,
      );

  final MoneyBucket pendingConfirm;
  final MoneyBucket shipping;
  final MoneyBucket delivered;
  final MoneyBucket cancelled;
  final double totalSpent;
}

class BookListItem {
  BookListItem({
    required this.raw,
    required this.id,
    this.title,
    this.sellingPrice,
    this.stockQuantity,
    this.imageUrl,
    this.deletedAt,
  });

  final Map<String, dynamic> raw;
  final int id;
  final String? title;
  final double? sellingPrice;
  final int? stockQuantity;
  final String? imageUrl;
  final String? deletedAt;

  factory BookListItem.fromJson(Map<String, dynamic> j) {
    return BookListItem(
      raw: j,
      id: j['id'] as int,
      title: j['title'] as String?,
      sellingPrice: _numToDouble(j['selling_price']),
      stockQuantity: j['stock_quantity'] as int?,
      imageUrl: j['image_url'] as String?,
      deletedAt: j['deleted_at']?.toString(),
    );
  }
}

class PageResult<T> {
  PageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  final List<T> items;
  final int total;
  final int page;
  final int size;
}

PageResult<BookListItem> parseBookPage(Map<String, dynamic> j) {
  final itemsRaw = j['items'];
  final list = <BookListItem>[];
  if (itemsRaw is List) {
    for (final e in itemsRaw) {
      if (e is Map<String, dynamic>) {
        list.add(BookListItem.fromJson(e));
      }
    }
  }
  return PageResult<BookListItem>(
    items: list,
    total: j['total'] as int? ?? list.length,
    page: j['page'] as int? ?? 1,
    size: j['size'] as int? ?? list.length,
  );
}
