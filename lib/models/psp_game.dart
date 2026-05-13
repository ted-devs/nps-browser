class PspGame {
  final String titleId;
  final String region;
  final String name;
  final String pkgLink;
  final String zrif;
  final String contentId;
  final int fileSize;
  final bool isDlc;

  PspGame({
    required this.titleId,
    required this.region,
    required this.name,
    required this.pkgLink,
    required this.zrif,
    required this.contentId,
    required this.fileSize,
    this.isDlc = false,
  });

  factory PspGame.fromCsv(List<dynamic> row, {bool isDlc = false}) {
    if (isDlc) {
      // DLC columns: 0:Title ID, 1:Region, 2:Name, 3:PKG, 4:Content ID, 5:Last Mod, 6:RAP, 7:DL RAP, 8:File Size
      return PspGame(
        titleId: row.length > 0 ? row[0].toString() : '',
        region: row.length > 1 ? row[1].toString() : '',
        name: row.length > 2 ? row[2].toString() : '',
        pkgLink: row.length > 3 ? row[3].toString() : '',
        contentId: row.length > 4 ? row[4].toString() : '',
        zrif: row.length > 6 ? row[6].toString() : '',
        fileSize: row.length > 8 ? int.tryParse(row[8].toString()) ?? 0 : 0,
        isDlc: true,
      );
    } else {
      // Game columns: 0:Title ID, 1:Region, 2:Type, 3:Name, 4:PKG, 5:Content ID, 6:Last Mod, 7:RAP, 8:DL RAP, 9:File Size
      return PspGame(
        titleId: row.length > 0 ? row[0].toString() : '',
        region: row.length > 1 ? row[1].toString() : '',
        name: row.length > 3 ? row[3].toString() : '',
        pkgLink: row.length > 4 ? row[4].toString() : '',
        contentId: row.length > 5 ? row[5].toString() : '',
        zrif: row.length > 7 ? row[7].toString() : '',
        fileSize: row.length > 9 ? int.tryParse(row[9].toString()) ?? 0 : 0,
        isDlc: false,
      );
    }
  }
}
