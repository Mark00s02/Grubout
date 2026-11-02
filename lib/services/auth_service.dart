import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _db = DatabaseService();
  static const _keyUserId = 'user_id';
  static const _iterations = 10000;

  /// Salted, iterated SHA-256. Stored as `v2$<salt>$<hash>`.
  String _hash(String password, {String? salt}) {
    salt ??= base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    List<int> bytes = utf8.encode('$salt:$password');
    for (var i = 0; i < _iterations; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return 'v2\$$salt\$${base64Url.encode(bytes)}';
  }

  // The original app used a weak 31-multiplier hash. Accounts created with it
  // still sign in and are upgraded to the salted hash on their next login.
  String _legacyHash(String password) {
    int h = 0;
    for (final c in password.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }

  bool _verify(String password, String stored) {
    if (stored.startsWith('v2\$')) {
      final parts = stored.split('\$');
      if (parts.length != 3) return false;
      return _hash(password, salt: parts[1]) == stored;
    }
    return _legacyHash(password) == stored;
  }

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final normalized = email.toLowerCase().trim();
    if (await _db.getUserByEmail(normalized) != null) {
      throw 'An account with this email already exists';
    }
    final saved = await _db.insertUser(AppUser(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      passwordHash: _hash(password),
      createdAt: DateTime.now(),
    ));
    await _persistSession(saved.id!);
    return saved;
  }

  Future<AppUser> login({required String email, required String password}) async {
    var user = await _db.getUserByEmail(email.toLowerCase().trim());
    if (user == null) throw 'No account found with that email';
    if (!_verify(password, user.passwordHash)) throw 'Incorrect password';
    if (!user.passwordHash.startsWith('v2\$')) {
      user = user.copyWith(passwordHash: _hash(password));
      await _db.updateUser(user);
    }
    await _persistSession(user.id!);
    return user;
  }

  Future<void> changePassword(AppUser user, String current, String next) async {
    if (!_verify(current, user.passwordHash)) throw 'Current password is incorrect';
    await _db.updateUser(user.copyWith(passwordHash: _hash(next)));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }

  Future<void> deleteAccount(int userId) async {
    await _db.deleteUser(userId);
    await logout();
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
