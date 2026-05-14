class PspGame {
  final String titleId;
  final String region;
  final String name;
  final String pkgLink;
  final String zrif;
  final String contentId;
  final int fileSize;
  PspGame({
    required this.titleId,
    required this.region,
    required this.name,
    required this.pkgLink,
    required this.zrif,
    required this.contentId,
    required this.fileSize,
  });

  factory PspGame.fromCsv(List<dynamic> row) {
    return PspGame(
      titleId: row.length > 0 ? row[0].toString() : '',
      region: row.length > 1 ? row[1].toString() : '',
      name: row.length > 3 ? row[3].toString() : '',
      pkgLink: row.length > 4 ? row[4].toString() : '',
      contentId: row.length > 5 ? row[5].toString() : '',
      zrif: row.length > 7 ? row[7].toString() : '',
      fileSize: row.length > 9 ? int.tryParse(row[9].toString()) ?? 0 : 0,
    );
  }

  factory PspGame.fromJson(Map<String, dynamic> json) {
    return PspGame(
      titleId: json['titleId'],
      region: json['region'],
      name: json['name'],
      pkgLink: json['pkgLink'],
      zrif: json['zrif'],
      contentId: json['contentId'],
      fileSize: json['fileSize'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titleId': titleId,
      'region': region,
      'name': name,
      'pkgLink': pkgLink,
      'zrif': zrif,
      'contentId': contentId,
      'fileSize': fileSize,
    };
  }
}
