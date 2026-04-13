import '../models/user.dart';
import 'auth_service.dart';

class LocalAuthService implements AuthService {
  AppUser? _sessionUser;
  final Map<String, String> _users = {}; // email -> password (MVP only)

  @override
  Future<AppUser?> register(String email, String password) async {
    if (_users.containsKey(email)) {
      throw Exception('User already exists');
    }
    _users[email] = password;
    return AppUser(
      id: email.replaceAll('@', '_').replaceAll('.', '_'),
      email: email,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AppUser?> login(String email, String password) async {
    if (!_users.containsKey(email) || _users[email] != password) {
      throw Exception('Invalid email or password');
    }
    _sessionUser = AppUser(
      id: email.replaceAll('@', '_').replaceAll('.', '_'),
      email: email,
      createdAt: DateTime.now(),
    );
    return _sessionUser;
  }

  @override
  Future<void> logout() async {
    _sessionUser = null;
  }

  @override
  Future<AppUser?> currentUser() async => _sessionUser;
}