import 'package:flutter/material.dart';

Widget buildPlatformFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return ColoredBox(
    color: const Color(0xFFE8E4DC),
    child: SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.image_outlined)),
    ),
  );
}
