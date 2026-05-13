class CoverArtService {
  static String getCoverUrl(String titleId) {
    // HexFlow-Covers uses TitleID without hyphens, e.g., UCUS98653.png
    String cleanId = titleId.replaceAll('-', '');
    
    return 'https://raw.githubusercontent.com/VitaHEX-Games/hexflow-covers/main/Covers/PSP/$cleanId.png';
  }
}
