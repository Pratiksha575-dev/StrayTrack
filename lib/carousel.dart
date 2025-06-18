import 'dart:async';
import 'package:flutter/material.dart';

class Carousel extends StatefulWidget {
  const Carousel({super.key});

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final List<String> _imageUrls = [
    'https://images.pexels.com/photos/1108099/pexels-photo-1108099.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
    'https://images.pexels.com/photos/1198802/pexels-photo-1198802.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
    'https://images.pexels.com/photos/245035/pexels-photo-245035.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
    'https://images.pexels.com/photos/3687770/pexels-photo-3687770.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
    'https://images.pexels.com/photos/2607541/pexels-photo-2607541.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2',
  ];

  final PageController _pageController = PageController();
  late Timer _timer;
  final Duration _scrollDuration = const Duration(seconds: 3);
  final Duration _animationDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(_scrollDuration, (Timer timer) {
      if (_pageController.hasClients) {
        final int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        _pageController.animateToPage(
          nextPage % _imageUrls.length,
          duration: _animationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 410.0, // Increase the height to expand vertically
      child: PageView.builder(
        controller: _pageController,
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return _buildCarouselItem(_imageUrls[index]);
        },
      ),
    );
  }

  Widget _buildCarouselItem(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(9.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover, // Ensure images cover the container
          ),
        ),
      ),
    );
  }
}
