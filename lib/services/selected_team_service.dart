import 'package:shared_preferences/shared_preferences.dart';

class SelectedTeamService {
  static const String _selectedTeamIdKey = 'selected_team_id';
  static const String _selectedTeamNameKey = 'selected_team_name';

  static Future<void> saveSelectedTeam({
    required String teamId,
    required String teamName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_selectedTeamIdKey, teamId);
    await prefs.setString(_selectedTeamNameKey, teamName);
  }

  static Future<String?> getSelectedTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedTeamIdKey);
  }

  static Future<String?> getSelectedTeamName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedTeamNameKey);
  }

  static Future<void> clearSelectedTeam() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_selectedTeamIdKey);
    await prefs.remove(_selectedTeamNameKey);
  }
}