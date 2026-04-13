import '../models/user.dart';

abstract class AuthService {
  Future<AppUser?> login(String email, String password);
  Future<AppUser?> register(String email, String password);
  Future<void> logout();
  Future<AppUser?> currentUser();
}