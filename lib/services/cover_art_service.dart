class CoverArtService {
  static String getCoverUrl(String titleId) {
    // Strip hyphens if any, though NPS usually gives them like "UCUS-98653" or "UCUS98653"
    // The psp-covers repo uses the format with hyphens, e.g. UCUS-98653.jpg
    // But let's ensure it has the hyphen.
    String formattedId = titleId;
    if (titleId.length == 9 && !titleId.contains('-')) {
      formattedId = '${titleId.substring(0, 4)}-${titleId.substring(4)}';
    }
    
    return 'https://raw.githubusercontent.com/xlenore/psp-covers/main/covers/$formattedId.jpg';
  }
}
