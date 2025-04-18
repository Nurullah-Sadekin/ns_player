import 'package:flutter/material.dart';
import 'package:ns_player/ns_player.dart';

/// A widget for loading UI that use while waiting for the video to load.
class VideoLoading extends StatelessWidget {
  /// Constructor
  const VideoLoading({
    super.key,
    this.loadingStyle,
    required this.thumbUrl,
  });

  /// A model class to provide the custom style for the loading widget.
  final VideoLoadingStyle? loadingStyle;
  final String thumbUrl;

  @override
  Widget build(BuildContext context) {
    return loadingStyle?.loading ??
        Container(
          color: loadingStyle?.loadingBackgroundColor ?? Colors.grey,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loadingStyle?.loadingIndicatorValueColor ?? Colors.amber,
                  ),
                  backgroundColor: loadingStyle?.loadingIndicatorBgColor,
                  color: loadingStyle?.loadingIndicatorColor,
                  strokeWidth: loadingStyle?.loadingIndicatorWidth ?? 4.0,
                  semanticsLabel: loadingStyle?.indicatorSemanticsLabel,
                  semanticsValue: loadingStyle?.indicatorSemanticsValue,
                  value: loadingStyle?.indicatorInitialValue,
                ),
                SizedBox(
                  height: loadingStyle?.spaceBetweenIndicatorAndText ?? 8.0,
                ),
                Visibility(
                  visible: loadingStyle?.showLoadingText ?? true,
                  child: Text(
                    loadingStyle?.loadingText ?? 'Loading...',
                    style: loadingStyle?.loadingTextStyle,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
