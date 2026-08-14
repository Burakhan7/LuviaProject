// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Giriş yapmış kullanıcı (yoksa null)
  User? get currentUser => _auth.currentUser;

  // Kullanıcı misafir mi (anonim mi)?
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // Giriş durumu değişimini dinle (giriş/çıkış)
  Stream<User?> get authState => _auth.authStateChanges();

  // Misafir (anonim) giriş — uygulama ilk açıldığında çağrılır
  Future<String?> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mesaj(e.code);
    }
  }

  // Kayıt ol
  // Eğer kullanıcı MİSAFİR ise: anonim hesabı gerçek hesaba YÜKSELT (userId korunur, veriler kalır)
  // Değilse: normal yeni hesap oluştur
  Future<String?> signUp(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        // Misafir → gerçek hesaba yükselt (linkleme). userId AYNI kalır.
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.linkWithCredential(credential);
      } else {
        // Normal kayıt
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      return null;
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

  // Şifremi unuttum — sıfırlama e-postası gönder
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
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
        return 'Bu e-posta ile kayıt bulunamadı.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta ya da şifre hatalı.';
      case 'credential-already-in-use':
        return 'Bu e-posta zaten başka bir hesapta kullanılıyor.';
      case 'requires-recent-login':
        return 'Bu işlem için tekrar giriş yapman gerekiyor.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
