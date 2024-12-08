import 'package:flutter/material.dart';
import 'package:ns_player/ns_player.dart';
import 'package:ns_player/src/utils/extensions/video_controller_extensions.dart';
import 'package:video_player/video_player.dart';

class PlayerBottomBar extends StatefulWidget {
   const PlayerBottomBar({super.key,
    required this.controller,
    required this.showBottomBar,
    required this.fullScreen,
    this.onPlayButtonTap,
    this.videoDuration = "00:00:00",
    this.videoSeek = "00:00:00",
    this.videoStyle = const VideoStyle(),
    this.onFastForward,
    this.onRewind,
    required this.onFullScreenIconTap,
    this.onFullScreen,
    this.hideFullScreenButton,
  });
  final VideoPlayerController controller;
  final VoidCallback? onFullScreenIconTap;
  final bool fullScreen ;
  final bool showBottomBar;
  final String videoSeek;
  final String videoDuration;
  final void Function()? onPlayButtonTap;
  final VoidCallback? onFullScreen;
  final bool? hideFullScreenButton;
  final VideoStyle videoStyle;
  final ValueChanged<VideoPlayerValue>? onRewind;
  final ValueChanged<VideoPlayerValue>? onFastForward;

  @override
  State<PlayerBottomBar> createState() => _PlayerBottomBarState();
}

class _PlayerBottomBarState extends State<PlayerBottomBar> {
  @override
  Widget build(BuildContext context,) {
    return Visibility(
      visible: widget.showBottomBar,
      child: Padding(
        padding: widget.fullScreen
            ? const EdgeInsets.symmetric(horizontal: 20)
            :  widget.videoStyle.bottomBarPadding,
        child: AspectRatio(
          aspectRatio: 16/9,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: widget.videoStyle.videoDurationsPadding ??
                      const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: widget.fullScreen
                        ? MediaQuery.of(context).size.width/3
                        : MediaQuery.of(context).size.width/2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            widget.controller.rewind().then((value) {
                              widget.onRewind?.call(widget.controller.value);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: widget.videoStyle.backwardIcon ??
                                Icon(
                                  Icons.replay_10_rounded,
                                  color: widget.videoStyle.forwardIconColor,
                                  size: widget.fullScreen ? 25: 20,
                                  // size: videoStyle.forwardAndBackwardBtSize,
                                )
                          ),
                        ),
                        widget.controller.value.isBuffering
                        && widget.controller.value.isCompleted == false
                            ? const CircularProgressIndicator(
                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : InkWell(
                          onTap: widget.onPlayButtonTap,
                          // onTap: widget.onFullScreen,
                          child: () {
                            var defaultIcon = Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child:  Icon(
                                widget.controller.value.isPlaying
                                    ? Icons.pause_outlined
                                    : Icons.play_arrow_outlined,
                                color: widget.videoStyle.playButtonIconColor ??
                                    Colors.white,
                                size: widget.fullScreen ? 35: 30,
                                // videoStyle.playButtonIconSize ?? (fullScreen ? 35: 25),
                              ),
                            );
                            if (widget.videoStyle.playIcon != null &&
                                widget.videoStyle.pauseIcon == null) {
                              return widget.controller.value.isPlaying
                                  ? defaultIcon
                                  : widget.videoStyle.playIcon;
                            }
                            else if (widget.videoStyle.pauseIcon != null &&
                                widget.videoStyle.playIcon == null) {
                              return widget.controller.value.isPlaying
                                  ? widget.videoStyle.pauseIcon
                                  : defaultIcon;
                            }
                            else if (widget.videoStyle.playIcon != null &&
                                widget.videoStyle.pauseIcon != null) {
                              return widget.controller.value.isPlaying
                                  ? widget.videoStyle.pauseIcon
                                  : widget.videoStyle.playIcon;
                            }
                            return defaultIcon;
                          }(),
                        ),
                        InkWell(
                          onTap: () {
                            widget.controller.fastForward().then((value) {
                              widget.onFastForward?.call(widget.controller.value);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child:  widget.videoStyle.forwardIcon ??
                                Icon(
                                  Icons.forward_10_rounded,
                                  color: widget.videoStyle.forwardIconColor,
                                  size: widget.fullScreen ? 25: 20,
                                  // size: videoStyle.forwardAndBackwardBtSize,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            widget.videoSeek,
                            style: widget.videoStyle.videoSeekStyle ??
                                const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        Text(
                          " / ",
                          style: widget.videoStyle.videoSeekStyle ??
                              const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        Text(
                          widget.videoDuration,
                          style: widget.videoStyle.videoDurationStyle ??
                              const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                        ),
                        const Spacer(),
                        if (widget.hideFullScreenButton == true)
                          const SizedBox()
                        else
                        InkWell(
                          onTap: widget.onFullScreen,
                          child: Container(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: widget.videoStyle.fullscreenIcon ??
                                  Icon(
                                    widget.fullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                    color: widget.videoStyle.fullScreenIconColor,
                                    size: widget.videoStyle.fullScreenIconSize,
                                  ),
                            ),
                          ),
                        )
                      ],
                    ),
                    VideoProgressIndicator(
                      widget.controller,
                      allowScrubbing: widget.videoStyle.allowScrubbing ?? true,
                      colors: widget.videoStyle.progressIndicatorColors ??
                          const VideoProgressColors(
                            playedColor: Color.fromARGB(255, 15, 214, 207),
                            bufferedColor: Color.fromARGB(255, 20, 98, 101),
                            backgroundColor: Color.fromARGB(27, 255, 255, 255),

                          ),
                      padding: widget.videoStyle.progressIndicatorPadding ?? const EdgeInsets.only(top: 15.0),
                    ),
                    widget.fullScreen
                        ? const SizedBox(height: 30,)
                        : const SizedBox(height: 0,),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Duration durationRangeToDuration(List<DurationRange> durationRange) {
    if (durationRange.isEmpty) {
      return Duration.zero;
    }
    return durationRange.first.end;
  }
}
