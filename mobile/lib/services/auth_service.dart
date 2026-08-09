// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Giriş yapmış kullanıcı (yoksa null)
  User? get currentUser => _auth.currentUser;

  // Giriş durumu değişimini dinle (giriş/çıkış)
  Stream<User?> get authState => _auth.authStateChanges();

  // Kayıt ol
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      return _mesaj(e.code);
    }
  }

  // Giriş yap
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mesaj(e.code);
    }
  }

  // Çıkış
  Future<void> signOut() => _auth.signOut();

  // Firebase hata kodlarını Türkçe mesaja çevir
  String _mesaj(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter).';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta ya da şifre hatalı.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
