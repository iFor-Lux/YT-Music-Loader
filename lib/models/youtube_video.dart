class YouTubeVideo {
  final String id;
  final String title;
  final String thumbnail;
  final String channelTitle;
  final String duration;
  final int viewCount;
  final String publishedAt;
  String? nextPageToken; // Para paginación
  bool isSelected;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.channelTitle,
    required this.duration,
    required this.viewCount,
    required this.publishedAt,
    this.nextPageToken,
    this.isSelected = false,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      id: json['id'] is Map ? json['id']['videoId'] ?? '' : json['id'] ?? '',
      title: json['snippet']['title'] ?? '',
      thumbnail: json['snippet']['thumbnails']['high']['url'] ?? '',
      channelTitle: json['snippet']['channelTitle'] ?? '',
      duration: json['duration'] ?? 'N/A',
      viewCount: int.tryParse(json['viewCount'] ?? '0') ?? 0,
      publishedAt: json['snippet']['publishedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'channelTitle': channelTitle,
      'duration': duration,
      'viewCount': viewCount,
      'publishedAt': publishedAt,
      'nextPageToken': nextPageToken,
      'isSelected': isSelected,
    };
  }

  YouTubeVideo copyWith({
    String? id,
    String? title,
    String? thumbnail,
    String? channelTitle,
    String? duration,
    int? viewCount,
    String? publishedAt,
    String? nextPageToken,
    bool? isSelected,
  }) {
    return YouTubeVideo(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      channelTitle: channelTitle ?? this.channelTitle,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt ?? this.publishedAt,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
