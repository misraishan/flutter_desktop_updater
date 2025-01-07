class AppArchiveModel {
  final String appName;
  final String description;
  final List<ItemModel> items;

  AppArchiveModel({
    required this.appName,
    required this.description,
    required this.items,
  });

  factory AppArchiveModel.fromJson(Map<String, dynamic> json) {
    return AppArchiveModel(
      appName: json['appName'],
      description: json['descriptipn'],
      items: List<ItemModel>.from(json['items'].map((x) => ItemModel.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'descriptipn': description,
      'items': List<dynamic>.from(items.map((x) => x.toJson())),
    };
  }
}

class ItemModel {
  final String version;
  final int shortVersion;
  final List<ChangeModel> changes;
  final String date;
  final bool mandatory;
  final String url;
  final String platform;
  final List<FileHashModel> hashes;

  ItemModel({
    required this.version,
    required this.shortVersion,
    required this.changes,
    required this.date,
    required this.mandatory,
    required this.url,
    required this.platform,
    required this.hashes,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      version: json['version'],
      shortVersion: json['shortVersion'],
      changes: List<ChangeModel>.from(json['changes'].map((x) => ChangeModel.fromJson(x))),
      date: json['date'],
      mandatory: json['mandatory'],
      url: json['url'],
      platform: json['platform'],
      hashes: List<FileHashModel>.from(json['hashes'].map((x) => FileHashModel.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'shortVersion': shortVersion,
      'changes': List<dynamic>.from(changes.map((x) => x.toJson())),
      'date': date,
      'mandatory': mandatory,
      'url': url,
      'platform': platform,
      'hashes': List<dynamic>.from(hashes.map((x) => x.toJson())),
    };
  }
}

class ChangeModel {
  final String? type;
  final String message;

  ChangeModel({
    this.type,
    required this.message,
  });

  factory ChangeModel.fromJson(Map<String, dynamic> json) {
    return ChangeModel(
      type: json['type'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
    };
  }
}

class FileHashModel {
  final String filePath;
  final String calculatedHash;
  final int length;

  FileHashModel({
    required this.filePath,
    required this.calculatedHash,
    required this.length,
  });

  factory FileHashModel.fromJson(Map<String, dynamic> json) {
    return FileHashModel(
      filePath: json['path'],
      calculatedHash: json['calculatedHash'],
      length: json['length'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': filePath,
      'calculatedHash': calculatedHash,
      'length': length,
    };
  }
}