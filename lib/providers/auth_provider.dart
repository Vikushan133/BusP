import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  auth.User? _firebaseUser;
  AppUser? _user;
  bool _isLoading = true;
  bool _isInitialized = false;

  auth.User? get firebaseUser => _firebaseUser;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    FirebaseService.authStateChanges.listen((auth.User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _user = null;
      }
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    _user = await FirebaseService.getUserData(uid);
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await FirebaseService.signIn(email, password);
      return true;
    } on auth.FirebaseAuthException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      await FirebaseService.register(email, password, firstName, lastName);
      return true;
    } on auth.FirebaseAuthException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(String firstName, String lastName) async {
    if (_firebaseUser != null) {
      await FirebaseService.updateUser(_firebaseUser!.uid, firstName, lastName);
      await _loadUserData(_firebaseUser!.uid);
    }
  }
}