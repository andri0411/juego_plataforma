import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    // Force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Revert to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors
          .transparent, // Transparent to show what's behind if needed, or black
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background: Golden Blur
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB8860B), // Dark Goldenrod
                  Color(0xFFFFD700), // Gold
                  Color(0xFFDAA520), // Goldenrod
                ],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.4,
                ), // Overlay to darken slightly
              ),
            ),
          ),

          // Botón "X" en la esquina superior izquierda
          Positioned(
            top: 24,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              tooltip: 'Cerrar',
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 32,
                right: 32,
                top: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (!_isLogin) ...[
                      const CustomInputField(
                        hintText: 'Nombre de usuario',
                        obscureText: false,
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const CustomInputField(
                      hintText: 'Correo electrónico',
                      obscureText: false,
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 16),

                    const CustomInputField(
                      hintText: 'Contraseña',
                      obscureText: true,
                      icon: Icons.lock,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 8,
                      ),
                      onPressed: () {
                        // Acción de login/registro
                      },
                      child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
                    ),

                    const SizedBox(height: 24),

                    if (_isLogin) ...[
                      const Text(
                        'O inicia con',
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Spectral',
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement Google Sign In
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              'assets/images/google.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? '¿No tienes cuenta? Regístrate aquí'
                            : '¿Ya tienes cuenta? Inicia sesión',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Spectral',
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom input field widget
class CustomInputField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final IconData icon;

  const CustomInputField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.icon,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextField(
        controller: _controller,
        obscureText: widget.obscureText,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Spectral',
          fontSize: 18,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            widget.icon,
            color: (_isFocused || hasText)
                ? const Color(0xFFFFD700)
                : Colors.white54,
          ),
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontFamily: 'Spectral',
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasText ? const Color(0xFFFFD700) : Colors.white24,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
