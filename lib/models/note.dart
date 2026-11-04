import '../theme/app_theme.dart';

class Note {
  Note({
    required this.id,
    this.title = '',
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
    this.favorite = false,
    this.paper = 0,
    this.mood = 0,
    List<String>? images,
  }) : images = images ?? <String>[];

  final String id;
  String title;
  String body;
  DateTime createdAt;
  DateTime updatedAt;
  bool pinned;
  bool favorite;

  /// 便签纸色索引，对应 [Palette.notePapers]
  int paper;

  /// 心情索引，对应 [Palette.moodGlyphs]
  int mood;

  /// 本机图片文件名，实体存放在应用私有目录的 media 文件夹里
  final List<String> images;

  String get displayTitle {
    final t = title.trim();
    return t.isEmpty ? '无题手记' : t;
  }

  String get preview {
    final text = body.trim().replaceAll(RegExp(r'\n+'), ' ');
    return text.isEmpty ? '……' : text;
  }

  int get charCount => body.replaceAll(RegExp(r'\s'), '').length;

  /// 取标题（或正文）首字，作为便签左上角的印章字
  String get monogram {
    final source = title.trim().isNotEmpty ? title.trim() : body.trim();
    if (source.isEmpty) return '筆';
    return source.substring(0, 1);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pinned': pinned,
    'favorite': favorite,
    'paper': paper,
    'mood': mood,
    'images': images,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Note(
      id: json['id'] as String? ?? 'n${now.microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      pinned: json['pinned'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
      paper: (json['paper'] as num?)?.toInt() ?? 0,
      mood: (json['mood'] as num?)?.toInt() ?? 0,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
