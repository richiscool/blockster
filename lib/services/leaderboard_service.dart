import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String name;
  final int score;

  LeaderboardEntry({required this.name, required this.score});

  Map<String, dynamic> toJson() {
    return {'name': name, 'score': score};
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'] as String,
      score: json['score'] as int,
    );
  }
}

class LeaderboardService {
  static const String _leaderboardKey = 'blockster_leaderboard';

  static Future<void> addEntry(String name, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final leaderboard = await getLeaderboard();

    leaderboard.add(LeaderboardEntry(name: name, score: score));
    leaderboard.sort((a, b) => b.score.compareTo(a.score));

    if (leaderboard.length > 10) {
      leaderboard.removeRange(10, leaderboard.length);
    }

    final jsonList = leaderboard.map((entry) => entry.toJson()).toList();
    await prefs.setString(_leaderboardKey, _encodeList(jsonList));
  }

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_leaderboardKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final jsonList = _decodeList(jsonString);
    return jsonList.map((json) => LeaderboardEntry.fromJson(json)).toList();
  }

  static String _encodeList(List<Map<String, dynamic>> list) {
    return list.map((entry) => '${entry['name']}|${entry['score']}').join(';');
  }

  static List<Map<String, dynamic>> _decodeList(String encoded) {
    return encoded.split(';').map((entry) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        return {'name': parts[0], 'score': int.parse(parts[1])};
      }
      return {'name': '', 'score': 0};
    }).toList();
  }
}
