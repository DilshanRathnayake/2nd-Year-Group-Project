class EducationItem {
  final String sinhalaLabel;
  final String videoAsset;

  const EducationItem({
    required this.sinhalaLabel,
    required this.videoAsset,
  });
}

const Map<String, List<EducationItem>> educationCategories = {
  'ක්‍රියා': [
    EducationItem(sinhalaLabel: 'පුළුවන්', videoAsset: 'assets/videos/can.mp4'),
    EducationItem(sinhalaLabel: 'එනවා', videoAsset: 'assets/videos/come.mp4'),
    EducationItem(sinhalaLabel: 'උයනවා', videoAsset: 'assets/videos/cook.mp4'),
    EducationItem(sinhalaLabel: 'අඬනවා', videoAsset: 'assets/videos/cry.mp4'),
    EducationItem(sinhalaLabel: 'කපනවා', videoAsset: 'assets/videos/cut.mp4'),
    EducationItem(sinhalaLabel: 'බොනවා', videoAsset: 'assets/videos/drink.mp4'),
    EducationItem(sinhalaLabel: 'කනවා', videoAsset: 'assets/videos/eat.mp4'),
    EducationItem(sinhalaLabel: 'යනවා', videoAsset: 'assets/videos/go.mp4'),
    EducationItem(sinhalaLabel: 'උදව්', videoAsset: 'assets/videos/help.mp4'),
    EducationItem(sinhalaLabel: 'බලනවා', videoAsset: 'assets/videos/look.mp4'),
    EducationItem(sinhalaLabel: 'ආදරය', videoAsset: 'assets/videos/love.mp4'),
    EducationItem(sinhalaLabel: 'හමුවෙනවා', videoAsset: 'assets/videos/meet.mp4'),
    EducationItem(sinhalaLabel: 'සෙල්ලම් කරනවා', videoAsset: 'assets/videos/play.mp4'),
    EducationItem(sinhalaLabel: 'දුවනවා', videoAsset: 'assets/videos/run.mp4'),
    EducationItem(sinhalaLabel: 'දකිනවා', videoAsset: 'assets/videos/see.mp4'),
    EducationItem(sinhalaLabel: 'විකුණනවා', videoAsset: 'assets/videos/sell.mp4'),
    EducationItem(sinhalaLabel: 'නිදාගන්නවා', videoAsset: 'assets/videos/sleep.mp4'),
    EducationItem(sinhalaLabel: 'උගන්වනවා', videoAsset: 'assets/videos/teach.mp4'),
    EducationItem(sinhalaLabel: 'කියනවා', videoAsset: 'assets/videos/tell.mp4'),
    EducationItem(sinhalaLabel: 'ඇවිදිනවා', videoAsset: 'assets/videos/walk.mp4'),
    EducationItem(sinhalaLabel: 'ලියනවා', videoAsset: 'assets/videos/write.mp4'),
  ],
  'වර්ණ': [
    EducationItem(sinhalaLabel: 'කළු', videoAsset: 'assets/videos/black.mp4'),
    EducationItem(sinhalaLabel: 'කොළ', videoAsset: 'assets/videos/green.mp4'),
    EducationItem(sinhalaLabel: 'දම්', videoAsset: 'assets/videos/purple.mp4'),
    EducationItem(sinhalaLabel: 'රතු', videoAsset: 'assets/videos/red.mp4'),
    EducationItem(sinhalaLabel: 'සුදු', videoAsset: 'assets/videos/white.mp4'),
    EducationItem(sinhalaLabel: 'කහ', videoAsset: 'assets/videos/yellow.mp4'),
  ],
  'අංක': [
    EducationItem(sinhalaLabel: 'එක', videoAsset: 'assets/videos/one.mp4'),
    EducationItem(sinhalaLabel: 'දෙක', videoAsset: 'assets/videos/two.mp4'),
    EducationItem(sinhalaLabel: 'තුන', videoAsset: 'assets/videos/three.mp4'),
    EducationItem(sinhalaLabel: 'හතර', videoAsset: 'assets/videos/four.mp4'),
    EducationItem(sinhalaLabel: 'පහ', videoAsset: 'assets/videos/five.mp4'),
  ],
  'ආචාර': [
    EducationItem(sinhalaLabel: 'ආයුබෝවන්', videoAsset: 'assets/videos/ayubowan.mp4'),
    EducationItem(sinhalaLabel: 'හලෝ', videoAsset: 'assets/videos/hello.mp4'),
    EducationItem(sinhalaLabel: 'කොහොමද', videoAsset: 'assets/videos/how_are_you.mp4'),
    EducationItem(sinhalaLabel: 'ස්තූතියි', videoAsset: 'assets/videos/thank_you.mp4'),
  ],
  'පුද්ගලයන්': [
    EducationItem(sinhalaLabel: 'සීයා', videoAsset: 'assets/videos/grand_father.mp4'),
    EducationItem(sinhalaLabel: 'ඔහු', videoAsset: 'assets/videos/he.mp4'),
    EducationItem(sinhalaLabel: 'මිනිසා', videoAsset: 'assets/videos/man.mp4'),
    EducationItem(sinhalaLabel: 'අම්මා', videoAsset: 'assets/videos/mother.mp4'),
    EducationItem(sinhalaLabel: 'මගේ', videoAsset: 'assets/videos/my.mp4'),
    EducationItem(sinhalaLabel: 'පුතා', videoAsset: 'assets/videos/son.mp4'),
    EducationItem(sinhalaLabel: 'අපි', videoAsset: 'assets/videos/us.mp4'),
    EducationItem(sinhalaLabel: 'ඔයා', videoAsset: 'assets/videos/you.mp4'),
  ],
  'වේලාව': [
    EducationItem(sinhalaLabel: 'පෙබරවාරි', videoAsset: 'assets/videos/february.mp4'),
    EducationItem(sinhalaLabel: 'ජනවාරි', videoAsset: 'assets/videos/january.mp4'),
    EducationItem(sinhalaLabel: 'ගෙදර', videoAsset: 'assets/videos/home.mp4'),
    EducationItem(sinhalaLabel: 'සල්ලි', videoAsset: 'assets/videos/money.mp4'),
    EducationItem(sinhalaLabel: 'වේලාව', videoAsset: 'assets/videos/time.mp4'),
    EducationItem(sinhalaLabel: 'කවදද', videoAsset: 'assets/videos/when.mp4'),
    EducationItem(sinhalaLabel: 'කොහෙද', videoAsset: 'assets/videos/where.mp4'),
    EducationItem(sinhalaLabel: 'ඇයි', videoAsset: 'assets/videos/why.mp4'),
  ],
};