import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    // Escuchar cambios de sesión
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login')) return 'Email o contraseña incorrectos';
    if (message.contains('Email not confirmed')) return 'Confirma tu email antes de continuar';
    if (message.contains('already registered')) return 'Este email ya tiene una cuenta';
    if (message.contains('Password should be')) return 'La contraseña debe tener al menos 6 caracteres';
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
