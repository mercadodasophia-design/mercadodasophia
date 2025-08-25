import 'product_model.dart';

class Feed {
  final String feedName;
  final String feedId;
  final String displayName;
  final String description;
  final int productCount;

  Feed({
    required this.feedName,
    required this.feedId,
    required this.displayName,
    required this.description,
    required this.productCount,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      feedName: json['feed_name'] ?? '',
      feedId: json['feed_id'] ?? '',
      displayName: json['display_name'] ?? json['feed_name'] ?? '',
      description: json['description'] ?? '',
      productCount: json['product_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feed_name': feedName,
      'feed_id': feedId,
      'display_name': displayName,
      'description': description,
      'product_count': productCount,
    };
  }

  @override
  String toString() {
    return 'Feed(feedName: $feedName, displayName: $displayName, productCount: $productCount)';
  }
}

class FeedProducts {
  final String feedName;
  final List<Product> products;
  final PaginationInfo pagination;

  FeedProducts({
    required this.feedName,
    required this.products,
    required this.pagination,
  });

  factory FeedProducts.fromJson(Map<String, dynamic> json) {
    return FeedProducts(
      feedName: json['feed_name'] ?? '',
      products: (json['products'] as List?)
          ?.map((p) => Product.fromMap(p, p['id'] ?? ''))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feed_name': feedName,
      'products': products.map((p) => p.toMap()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return 'FeedProducts(feedName: $feedName, products: ${products.length}, pagination: $pagination)';
  }
}

class PaginationInfo {
  final int pageNo;
  final int pageSize;
  final int totalCount;
  final bool hasNext;
  final int totalPages;

  PaginationInfo({
    required this.pageNo,
    required this.pageSize,
    required this.totalCount,
    required this.hasNext,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      pageNo: json['page_no'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      hasNext: json['has_next'] ?? false,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_no': pageNo,
      'page_size': pageSize,
      'total_count': totalCount,
      'has_next': hasNext,
      'total_pages': totalPages,
    };
  }

  @override
  String toString() {
    return 'PaginationInfo(pageNo: $pageNo, totalCount: $totalCount, hasNext: $hasNext)';
  }
}
