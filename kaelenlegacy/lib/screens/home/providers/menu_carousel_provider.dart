import 'package:flutter/material.dart';

class MenuCarousel extends StatefulWidget {
  final bool vertical;
  final ValueChanged<String>? onOptionChanged;
  final int selectedIndex;
  final ValueChanged<int>? onPageChanged; // <-- Nuevo parámetro

  const MenuCarousel({
    this.vertical = false,
    this.onOptionChanged,
    this.selectedIndex = 0,
    this.onPageChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends State<MenuCarousel> {
  final List<String> options = ['New\nGame', 'Store', 'Settings', 'Quit'];
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant MenuCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _pageController.page?.round()) {
      _pageController.jumpToPage(widget.selectedIndex);
    }
  }

  void _onTap(int index) {
    widget.onOptionChanged?.call(options[index]);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: widget.vertical ? Axis.vertical : Axis.horizontal,
      itemCount: options.length,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) {
        final isSelected = index == widget.selectedIndex;
        return Center(
          child: GestureDetector(
            onTap: () => _onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(vertical: isSelected ? 20 : 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  options[index],
                  maxLines: options[index].contains('\n') ? 2 : 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Spectral',
                    fontStyle: FontStyle.italic,
                    fontSize: isSelected ? 44 : 28,
                    color: isSelected ? Color(0xFFFFD700) : Colors.white54,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 8,
                        color: isSelected
                            ? Color(0xFFFFD700).withOpacity(0.5)
                            : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
