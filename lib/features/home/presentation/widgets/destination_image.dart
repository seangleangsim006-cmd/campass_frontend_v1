import 'package:flutter/material.dart';

class DestinationImage extends StatelessWidget {
  const DestinationImage({
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    super.key,
  });

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source);
    final isNetworkImage =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    final fallback = errorBuilder ?? _defaultErrorBuilder;

    return isNetworkImage
        ? Image.network(
            source,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const ColoredBox(
                color: Color(0xFFE8E5DF),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: fallback,
          )
        : Image.asset(
            source,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: fallback,
          );
  }

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const ColoredBox(
      color: Color(0xFFE8E5DF),
      child: Center(child: Icon(Icons.landscape_outlined)),
    );
  }
}
