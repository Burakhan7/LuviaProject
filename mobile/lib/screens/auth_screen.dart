import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLogin = true; // true=giriş, false=kayıt
  bool _loading = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      _snack('E-posta ve şifre gerekli');
      return;
    }

    setState(() => _loading = true);
    final error = _isLogin
        ? await _auth.signIn(email, pass)
        : await _auth.signUp(email, pass); // signUp misafiri otomatik yükseltir
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _snack(error);
    } else {
      // Başarılı: bu ekrandan çık (kullanıcı artık gerçek hesapla içeride)
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Önce e-posta adresini gir, sonra "Şifremi unuttum"a bas.');
      return;
    }
    setState(() => _loading = true);
    final error = await _auth.resetPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _snack(error);
    } else {
      _snack('Şifre sıfırlama bağlantısı e-postana gönderildi.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isGuest = _auth.isGuest; // misafirse "hesabını güvene al" vurgusu

    return Container(
      decoration: LuviaTheme.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: LuviaTheme.primary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.checkroom,
                    size: 60,
                    color: LuviaTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Luvia',
                    style: TextStyle(
                      fontSize: 32,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: LuviaTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Tekrar hoş geldin'
                        : (isGuest
                              ? 'Hesabını güvene al, kıyafetlerin kaybolmasın'
                              : 'Hesap oluştur'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  _field(_emailCtrl, 'E-posta', Icons.email_outlined, false),
                  const SizedBox(height: 14),
                  _field(_passCtrl, 'Şifre', Icons.lock_outline, true),

                  // Şifremi unuttum — sadece giriş modunda göster
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text(
                          'Şifremi unuttum',
                          style: TextStyle(
                            color: LuviaTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: LuviaTheme.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Hesabın yok mu? Kayıt ol'
                          : 'Zaten hesabın var mı? Giriş yap',
                      style: const TextStyle(color: LuviaTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool obscure,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LuviaTheme.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
