import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'providers/menu_carousel_provider.dart';
import 'package:provider/provider.dart';
import 'providers/settings_config_provider.dart';
import 'widgets/login_widget.dart';
import 'widgets/payment_widget.dart';
import '../../game/game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Non-nullable controller initialized with a dummy asset
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  bool _isInitialized = false;
  double _videoOpacity = 1.0;
  String _currentVideoAsset = _videoFlame;

  // Nueva variable para controlar la animación de carga
  bool _showPreHome = true;
  int _menuSelectedIndex = 0;
  double _zoomScale = 1.0;
  bool _isZooming = false;
  bool _isTransitioning = false;
  double _fadeToBlack = 0.0;
  bool _showDoor = false;
  bool _showCoinStore = false;
  int _coins = 1500;

  // Video asset constants
  static const String _videoFlame = 'assets/videos/flame.mp4';
  static const String _videoIntro = 'assets/videos/intro.mp4';
  static const String _videoNewGameIntro = 'assets/videos/newgameintro.mp4';
  static const String _videoShowMap = 'assets/videos/showmap.mp4';
  static const String _videoStore = 'assets/videos/store.mp4';
  static const String _videoSettings = 'assets/videos/settings.mp4';

  @override
  void initState() {
    super.initState();
    // Initialize with dummy controller
    _controller = VideoPlayerController.asset(_videoFlame);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Inicia con el video de carga principal
    _initAndPlayAsset(_videoFlame, looping: false, addPreListener: true);
  }

  Future<void> _initAndPlayAsset(
    String asset, {
    bool looping = false,
    bool addPreListener = false,
  }) async {
    try {
      // Dispose any existing controller safely
      try {
        await _controller.pause();
      } catch (_) {}
      try {
        await _controller.dispose();
      } catch (_) {}

      final newController = VideoPlayerController.asset(asset);
      debugPrint('📺 Inicializando video asset: $asset');
      await newController.initialize();
      debugPrint(
        '📺 Video initialized: $asset, duration=${newController.value.duration}, size=${newController.value.size}, isPlaying=${newController.value.isPlaying}',
      );
      if (!mounted) {
        await newController.dispose();
        return;
      }
      _controller = newController;
      // Capture volume synchronously after mounted check to avoid using
      // BuildContext across async gaps.
      final capturedVolume = context.read<SettingsConfigProvider>().volume;
      setState(() {
        _isInitialized = true;
        _currentVideoAsset = asset;
        _controller.setLooping(looping);
        _controller.setVolume(capturedVolume);
        _controller.play();
        _videoOpacity = 1.0;
      });
      _fadeController.forward();
      if (addPreListener) {
        _controller.addListener(_preHomeListener);
        debugPrint('🔔 Added pre-home listener for $asset');
      }
    } catch (e, st) {
      debugPrint('❌ Error inicializando video "$asset": $e');
      debugPrint('Stack trace: $st');
      // Mostrar un placeholder visual en caso de fallo
      if (!mounted) return;
      setState(() {
        _isInitialized = false;
      });
    }
  }

  void _preHomeListener() async {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    debugPrint(
      '🎬 preHomeListener: current=$_currentVideoAsset, pos=$position, dur=$duration',
    );
    if (duration.inMilliseconds > 0 && position >= duration) {
      _controller.removeListener(_preHomeListener);
      try {
        await _controller.pause();
      } catch (_) {}
      try {
        await _controller.dispose();
      } catch (_) {}
      // Cambia a la pantalla principal (home)
      if (!mounted) return;
      setState(() {
        _showPreHome = false;
        _isInitialized = false;
      });
      // Inicializa el video de fondo principal
      await _initAndPlayAsset(_videoIntro, looping: true);
    }
  }

  void _onMenuOptionChanged(String option) async {
    final cleanOption = option.replaceAll('\n', ' ');
    // Solo acciones especiales al tap en "New Game" y "Quit"
    if (cleanOption == 'New Game') {
      setState(() => _videoOpacity = 0.0);
      await Future.delayed(const Duration(milliseconds: 500));
      await _initAndPlayAsset(_videoNewGameIntro, looping: false);

      // Listener para pasar a showmap.mp4 al terminar newgameintro.mp4
      void newGameIntroListener() async {
        final duration = _controller.value.duration;
        final position = _controller.value.position;
        if (duration.inMilliseconds > 0 && position >= duration) {
          _controller.removeListener(newGameIntroListener);
          try {
            await _controller.pause();
          } catch (_) {}
          if (!mounted) return;
          await _initAndPlayAsset(_videoShowMap, looping: false);

          // Listener para mostrar la puerta al terminar showmap.mp4
          void showMapListener() async {
            final duration2 = _controller.value.duration;
            final position2 = _controller.value.position;
            if (duration2.inMilliseconds > 0 &&
                position2 >= duration2 &&
                !_showDoor) {
              _controller.removeListener(showMapListener);
              try {
                await _controller.pause();
              } catch (_) {}
              if (!mounted) return;
              setState(() {
                _showDoor = true;
              });
            }
          }

          _controller.addListener(showMapListener);
        }
      }

      _controller.addListener(newGameIntroListener);
    }
    if (cleanOption == 'Quit') {
      Future.delayed(const Duration(milliseconds: 300), () {
        SystemNavigator.pop();
      });
    }
  }

  Future<void> _changeVideo(String asset) async {
    setState(() => _videoOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      await _controller.pause();
    } catch (_) {}
    try {
      await _controller.dispose();
    } catch (_) {}
    _controller = VideoPlayerController.asset(asset);
    await _controller.initialize();
    if (asset == _videoIntro ||
        asset == _videoStore ||
        asset == _videoSettings) {
      _controller.setLooping(true);
    } else {
      _controller.setLooping(false);
    }
    if (!mounted) return;
    final capturedVolume = context.read<SettingsConfigProvider>().volume;
    _controller.setVolume(capturedVolume);
    setState(() {
      _isInitialized = true;
      _currentVideoAsset = asset;
      _videoOpacity = 0.0;
    });
    _controller.play();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _videoOpacity = 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            Stack(
              children: [
                AnimatedOpacity(
                  opacity: _videoOpacity,
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedScale(
                    scale: _zoomScale,
                    duration: const Duration(milliseconds: 600),
                    child: SizedBox.expand(child: VideoPlayer(_controller)),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _fadeToBlack,
                  duration: const Duration(milliseconds: 600),
                  child: Container(height: double.infinity),
                ),
                // Mostrar 5 puertas en fila al finalizar showmap.mp4
                if (_currentVideoAsset == _videoShowMap && _showDoor)
                  Stack(
                    children: [
                      // Puerta 1
                      Positioned(
                        top: 0,
                        left: MediaQuery.of(context).size.width / 2 - 320,
                        child: GestureDetector(
                          onTap: () async {
                            setState(() => _showDoor = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GameScreen(),
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/images/door.png',
                            width: 130,
                            height: 195,
                          ),
                        ),
                      ),
                      // Puerta 2
                      Positioned(
                        top: 100,
                        left: MediaQuery.of(context).size.width / 2 - 160,
                        child: GestureDetector(
                          onTap: null,
                          child: Image.asset(
                            'assets/images/door.png',
                            width: 130,
                            height: 195,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      // Puerta 3
                      Positioned(
                        top: 190,
                        left: MediaQuery.of(context).size.width / 2,
                        child: GestureDetector(
                          onTap: null,
                          child: Image.asset(
                            'assets/images/door.png',
                            width: 130,
                            height: 195,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      // Puerta 4
                      Positioned(
                        top: 40,
                        left: MediaQuery.of(context).size.width / 2 + 130 + 24,
                        child: GestureDetector(
                          onTap: null,
                          child: Image.asset(
                            'assets/images/door.png',
                            width: 130,
                            height: 195,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      // Puerta 5
                      Positioned(
                        top: 200,
                        left: MediaQuery.of(context).size.width / 2 + 2 * (130),
                        child: GestureDetector(
                          onTap: null,
                          child: Image.asset(
                            'assets/images/door.png',
                            width: 130,
                            height: 195,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_currentVideoAsset == _videoShowMap)
                  AnimatedOpacity(
                    opacity: _videoOpacity,
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedScale(
                      scale: _zoomScale,
                      duration: const Duration(milliseconds: 600),
                      child: SizedBox.expand(child: VideoPlayer(_controller)),
                    ),
                  ),
                if (_currentVideoAsset == _videoShowMap)
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: GestureDetector(
                      onTap: () async {
                        // Capture provider value before any `await` to avoid using
                        // BuildContext across async gaps (fixes analyzer warning).
                        final capturedVolume = context
                            .read<SettingsConfigProvider>()
                            .volume;
                        setState(() => _videoOpacity = 0.0);
                        await Future.delayed(const Duration(milliseconds: 300));
                        try {
                          await _controller.pause();
                        } catch (_) {}
                        try {
                          await _controller.dispose();
                        } catch (_) {}
                        _controller = VideoPlayerController.asset(_videoIntro);
                        await _controller.initialize();
                        if (!mounted) return;
                        setState(() {
                          _isInitialized = true;
                          _currentVideoAsset = _videoIntro;
                          _showPreHome = false;
                          _videoOpacity = 0.0;
                          _zoomScale = 1.0;
                          _fadeToBlack = 0.0;
                        });
                        _controller.setLooping(true);
                        _controller.setVolume(capturedVolume);
                        _controller.play();
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (!mounted) return;
                        setState(() {
                          _videoOpacity = 1.0;
                        });
                      },
                      child: const Text(
                        'exit',
                        style: TextStyle(
                          fontFamily: 'Spectral',
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w300,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 6,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // Efecto blur para Settings solo si el video es settings.mp4
          if (_isInitialized && _currentVideoAsset == _videoSettings)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuración',
                            style: TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 6,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Volumen',
                            style: TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Slider(
                            value: context
                                .watch<SettingsConfigProvider>()
                                .volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) {
                              debugPrint('Slider volumen cambiado: $value');
                              context.read<SettingsConfigProvider>().setVolume(
                                value,
                              );
                              _controller.setVolume(value);
                              debugPrint(
                                'VideoPlayerController volumen seteado: ${_controller.value.volume}',
                              );
                            },
                            activeColor: Colors.amber,
                            inactiveColor: Colors.white24,
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Cuenta',
                            style: TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Spectral',
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LoginWidget(),
                                ),
                              );
                            },
                            child: const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontFamily: 'Spectral',
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Widget para Tienda solo si el video es store.mp4
          if (_isInitialized && _currentVideoAsset == _videoStore)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                height: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      color: const Color.fromARGB(
                        255,
                        0,
                        0,
                        0,
                      ).withValues(alpha: 0.25),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_showCoinStore)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showCoinStore = false;
                                    });
                                  },
                                )
                              else
                                const SizedBox(width: 48), // Spacer to balance
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showCoinStore ? 'Monedas' : 'Tienda',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Spectral',
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 1,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 6,
                                            color: Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_showCoinStore) ...[
                                      // Removed coin counter from here
                                    ],
                                  ],
                                ),
                              ),
                              if (!_showCoinStore)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showCoinStore = true;
                                    });
                                  },
                                )
                              else
                                const SizedBox(width: 48), // Spacer to balance
                            ],
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: _showCoinStore
                                  ? [
                                      _buildStoreItem(
                                        Icons.monetization_on,
                                        'Pila de Monedas',
                                        '\$50 MXN',
                                        Colors.amber,
                                        isRealMoney: true,
                                        onTap: () async {
                                          final coinsPurchased =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PaymentWidget(
                                                        itemName:
                                                            'Pila de Monedas',
                                                        itemPrice: '\$50 MXN',
                                                        itemAmount:
                                                            '500 Monedas',
                                                      ),
                                                ),
                                              );
                                          if (coinsPurchased != null &&
                                              coinsPurchased is int) {
                                            setState(() {
                                              _coins += coinsPurchased;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.savings,
                                        'Bolsa de Monedas',
                                        '\$120 MXN',
                                        Colors.amberAccent,
                                        isRealMoney: true,
                                        onTap: () async {
                                          final coinsPurchased =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PaymentWidget(
                                                        itemName:
                                                            'Bolsa de Monedas',
                                                        itemPrice: '\$120 MXN',
                                                        itemAmount:
                                                            '1500 Monedas',
                                                      ),
                                                ),
                                              );
                                          if (coinsPurchased != null &&
                                              coinsPurchased is int) {
                                            setState(() {
                                              _coins += coinsPurchased;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.account_balance_wallet,
                                        'Cofre de Monedas',
                                        '\$250 MXN',
                                        Colors.orange,
                                        isRealMoney: true,
                                        onTap: () async {
                                          final coinsPurchased =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PaymentWidget(
                                                        itemName:
                                                            'Cofre de Monedas',
                                                        itemPrice: '\$250 MXN',
                                                        itemAmount:
                                                            '3500 Monedas',
                                                      ),
                                                ),
                                              );
                                          if (coinsPurchased != null &&
                                              coinsPurchased is int) {
                                            setState(() {
                                              _coins += coinsPurchased;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.diamond,
                                        'Tesoro Real',
                                        '\$350 MXN',
                                        Colors.cyanAccent,
                                        isRealMoney: true,
                                        onTap: () async {
                                          final coinsPurchased =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PaymentWidget(
                                                        itemName: 'Tesoro Real',
                                                        itemPrice: '\$350 MXN',
                                                        itemAmount:
                                                            '6000 Monedas',
                                                      ),
                                                ),
                                              );
                                          if (coinsPurchased != null &&
                                              coinsPurchased is int) {
                                            setState(() {
                                              _coins += coinsPurchased;
                                            });
                                          }
                                        },
                                      ),
                                    ]
                                  : [
                                      _buildStoreItem(
                                        Icons.favorite,
                                        'Poción de Vida',
                                        '500',
                                        Colors.redAccent,
                                        onTap: () {
                                          if (_coins >= 500) {
                                            setState(() {
                                              _coins -= 500;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Poción de Vida comprada!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.water_drop,
                                        'Poción de Maná',
                                        '300',
                                        Colors.blueAccent,
                                        onTap: () {
                                          if (_coins >= 300) {
                                            setState(() {
                                              _coins -= 300;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Poción de Maná comprada!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.handyman,
                                        'Espada de Hierro',
                                        '1500',
                                        Colors.blueGrey,
                                        onTap: () {
                                          if (_coins >= 1500) {
                                            setState(() {
                                              _coins -= 1500;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Espada de Hierro comprada!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.shield,
                                        'Escudo de Madera',
                                        '800',
                                        Colors.brown,
                                        onTap: () {
                                          if (_coins >= 800) {
                                            setState(() {
                                              _coins -= 800;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Escudo de Madera comprado!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.directions_run,
                                        'Botas Veloces',
                                        '1200',
                                        Colors.green,
                                        onTap: () {
                                          if (_coins >= 1200) {
                                            setState(() {
                                              _coins -= 1200;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Botas Veloces compradas!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.circle,
                                        'Anillo de Fuerza',
                                        '2500',
                                        Colors.amber,
                                        onTap: () {
                                          if (_coins >= 2500) {
                                            setState(() {
                                              _coins -= 2500;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Anillo de Fuerza comprado!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.security,
                                        'Amuleto Protección',
                                        '3000',
                                        Colors.purpleAccent,
                                        onTap: () {
                                          if (_coins >= 3000) {
                                            setState(() {
                                              _coins -= 3000;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Amuleto Protección comprado!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStoreItem(
                                        Icons.map,
                                        'Mapa del Tesoro',
                                        '5000',
                                        Colors.yellowAccent,
                                        onTap: () {
                                          if (_coins >= 5000) {
                                            setState(() {
                                              _coins -= 5000;
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '¡Mapa del Tesoro comprado!',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No tienes suficientes monedas',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Si no está inicializado, mostrar cargando (mejora UX)
          if (!_isInitialized)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Cargando...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

          // Solo muestra el home si terminó la animación de carga principal
          // Sombra izquierda: sólo cuando el fondo es el video por defecto (intro.mp4)
          if (!_showPreHome && _currentVideoAsset == _videoIntro)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.transparent, Colors.black54, Colors.black],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Center(
                  child: Text(
                    'Kaelen Legacy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 80,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        const Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 4,
                          color: Colors.black38,
                        ),
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 10,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (!_showPreHome &&
              _currentVideoAsset != _videoNewGameIntro &&
              _currentVideoAsset != _videoShowMap)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black54, Colors.black],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          if (!_showPreHome &&
              _isInitialized &&
              _currentVideoAsset != _videoNewGameIntro &&
              _currentVideoAsset != _videoShowMap)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
              right: 32,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: 120,
                child: MenuCarousel(
                  vertical: true,
                  onOptionChanged: (option) => _onMenuOptionChanged(option),
                  selectedIndex: _menuSelectedIndex,
                  onPageChanged: (index) async {
                    setState(() {
                      _menuSelectedIndex = index;
                    });
                    // Cambia el fondo/video al cambiar de opción
                    const options = ['New Game', 'Store', 'Settings', 'Quit'];
                    final option = options[index];
                    if (option == 'Store' &&
                        _currentVideoAsset != _videoStore) {
                      await _changeVideo(_videoStore);
                    } else if (option == 'Settings' &&
                        _currentVideoAsset != _videoSettings) {
                      await _changeVideo(_videoSettings);
                    } else if (option != 'Store' &&
                        option != 'Settings' &&
                        (_currentVideoAsset == _videoStore ||
                            _currentVideoAsset == _videoSettings)) {
                      await _changeVideo(_videoIntro);
                    }
                  },
                ),
              ),
            ),

          // Coin Counter (Top Right, avoiding Carousel)
          if (_isInitialized && _currentVideoAsset == _videoStore)
            Positioned(
              top: 40,
              right:
                  180, // Positioned to the left of the carousel (which is at right: 32, width: 120)
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_coins',
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreItem(
    IconData icon,
    String name,
    String price,
    Color iconColor, {
    bool isRealMoney = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 18,
                    color: isRealMoney ? Colors.greenAccent : Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isRealMoney) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
