import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _db = DatabaseService();
  static const _keyUserId = 'user_id';

  // Simple hash — for a production app use a proper crypto package
  String _hash(String password) {
    int h = 0;
    for (final c in password.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final existing = await _db.getUserByEmail(email.toLowerCase());
    if (existing != null) throw 'Email already registered';

    final user = AppUser(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    );
    final saved = await _db.insertUser(user);
    await _persistSession(saved.id!);
    return saved;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final user = await _db.getUserByEmail(email.toLowerCase().trim());
    if (user == null) throw 'No account found with that email';
    if (user.passwordHash != _hash(password)) throw 'Incorrect password';
    await _persistSession(user.id!);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  Future<AppUser?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    if (id == null) return null;
    return _db.getUserById(id);
  }

  Future<void> _persistSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }
}
