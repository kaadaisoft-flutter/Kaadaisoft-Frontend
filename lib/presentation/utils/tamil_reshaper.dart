class TamilReshaper {
  static String reshape(String input) {
    if (input.isEmpty) return input;

    // This is a simplified Tamil Unicode to Visual reshaper
    // for use with PDF libraries that don't support complex text shaping.
    // It handles common vowel sign placements.

    String result = input;

    // 1. Handle vowel signs that should appear BEFORE the consonant
    // ெ (0BC6), ே (0BC7), ை (0BC8)
    
    // We use a regex to find any character followed by one of these vowel signs
    // and swap them. Note: This doesn't handle consonant clusters (mei + uyir-mei) perfectly
    // but works for most common words.
    
    // Pattern: (Any consonant) + (vowel sign) -> (vowel sign) + (consonant)
    final preVowels = ['\u0bc6', '\u0bc7', '\u0bc8'];
    for (var v in preVowels) {
      final reg = RegExp('(.)($v)');
      result = result.replaceAllMapped(reg, (m) => '${m.group(2)}${m.group(1)}');
    }

    // 2. Handle split vowel signs
    // ொ (0BCA) = ெ + ா -> usually rendered as ெ + consonant + ா
    // ோ (0BCB) = ே + ா -> usually rendered as ே + consonant + ா
    // ௌ (0BCC) = ெ + ள -> usually rendered as ெ + consonant + ள
    
    // ொ (0BCA) -> ெ + consonant + ா
    result = result.replaceAllMapped(RegExp('(.)\u0bca'), (m) => '\u0bc6${m.group(1)}\u0bbe');
    
    // ோ (0BCB) -> ே + consonant + ா
    result = result.replaceAllMapped(RegExp('(.)\u0bcb'), (m) => '\u0bc7${m.group(1)}\u0bbe');
    
    // ௌ (0BCC) -> ெ + consonant + ள
    result = result.replaceAllMapped(RegExp('(.)\u0bcc'), (m) => '\u0bc6${m.group(1)}\u0bd7');

    return result;
  }
}
