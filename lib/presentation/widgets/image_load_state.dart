import 'package:flutter/material.dart';

class ImageLoadState extends StatefulWidget {
  final Widget Function(BuildContext context, bool imageLoadFailed, VoidCallback setFailed) builder;
  final Key? key;
  const ImageLoadState({this.key, required this.builder}) : super(key: key);

  @override
  State<ImageLoadState> createState() => _ImageLoadStateState();
}

class _ImageLoadStateState extends State<ImageLoadState> {
  bool _imageLoadFailed = false;

  void _setFailed() {
    if (mounted && !_imageLoadFailed) {
      setState(() {
        _imageLoadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _imageLoadFailed, _setFailed);
  }
}
