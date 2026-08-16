import 'dart:io';

import 'package:flutter/material.dart';

Widget buildPlatformFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
