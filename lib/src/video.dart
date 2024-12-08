import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ns_player/ns_player.dart';
import 'package:ns_player/src/model/models.dart';
import 'package:ns_player/src/utils/utils.dart';
import 'package:ns_player/src/widgets/video_loading.dart';
import 'package:ns_player/src/widgets/video_quality_picker.dart';
import 'package:ns_player/src/widgets/widget_bottombar.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'responses/regex_response.dart';
class NsPlayer extends StatefulWidget {
  final String url;
  final VideoStyle videoStyle;
  final VideoLoadingStyle videoLoadingStyle;
  final double aspectRatio;
  final void Function(bool fullScreenTurnedOn)? onFullScreen;
  final void Function(bool fullScreenTurnedOn)? onBackButtonTap;
  final void Function(String videoType)? onPlayingVideo;
  final void Function(bool isPlaying)? onPlayButtonTap;
  final ValueChanged<VideoPlayerValue>? onFastForward;
  final ValueChanged<VideoPlayerValue>? onRewind;
  final ValueChanged<VideoPlayerValue>? onPause;
  final ValueChanged<VideoPlayerValue>? onDispose;
  final ValueChanged<VideoPlayerValue>? onLiveDirectTap;
  final void Function(bool showMenu, bool m3u8Show)? onShowMenu;
  final void Function(VideoPlayerController controller)? onVideoInitCompleted;
  final Map<String, String>? headers;
  final bool autoPlayVideoAfterInit;
  final bool displayFullScreenAfterInit;
  final void Function(List<File>? files)? onCacheFileCompleted;
  final void Function(dynamic error)? onCacheFileFailed;
  final bool allowCacheFile;
  final Future<ClosedCaptionFile>? closedCaptionFile;
  final VideoPlayerOptions? videoPlayerOptions;
  final VoidCallback? onFullScreenIconTap;
  final bool? hideFullScreenButton;
   const NsPlayer({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.videoStyle = const VideoStyle(),
    this.videoLoadingStyle = const VideoLoadingStyle(),
    this.onFullScreen,
    this.onFullScreenIconTap,
    this.onPlayingVideo,
    this.onPlayButtonTap,
    this.onShowMenu,
    this.onFastForward,
    this.onRewind,
    this.headers,
    this.autoPlayVideoAfterInit = true,
    this.displayFullScreenAfterInit = false,
    this.allowCacheFile = false,
    this.onCacheFileCompleted,
    this.onCacheFileFailed,
    this.onVideoInitCompleted,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.onLiveDirectTap,
    this.onPause,
    this.onDispose,
    this.onBackButtonTap,
    this.hideFullScreenButton,
  });

  @override
  State<NsPlayer> createState() => _NsPlayerState();
}

class _NsPlayerState extends State<NsPlayer>
    with SingleTickerProviderStateMixin {
  String? playType;
  bool loop = false;
  late AnimationController controlBarAnimationController;
  Animation<double>? controlTopBarAnimation;
  VoidCallback? onFullScreenIconTap;
  Animation<double>? controlBottomBarAnimation;
  late VideoPlayerController controller;
  bool hasInitError = false;
  String? videoDuration;
  String? videoSeek;
  Duration? duration;
  double? videoSeekSecond;
  double? videoDurationSecond;
  List<M3U8Data> m3u8UrlList = [];
  List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  double playbackSpeed = 1.0;
  List<AudioModel> audioList = [];
  String? m3u8Content;
  String? subtitleContent;
  bool m3u8Show = false;
  bool fullScreen = false;
  bool showMenu = false;
  bool showSubtitles = false;
  bool? isOffline;
  String m3u8Quality = "Auto";
  Timer? showTime;
  OverlayEntry? overlayEntry;
  GlobalKey videoQualityKey = GlobalKey();
  Duration? lastPlayedPos;
  bool isAtLivePosition = true;
  bool hideQualityList = false;

  @override
  void initState() {
    super.initState();
    urlCheck(widget.url);
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
  }

  @override
  void dispose() {
    m3u8Clean();
    controller.dispose();
    controlBarAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (result) {
        if(fullScreen){
          setState(() {
            fullScreen = !fullScreen;
            widget.onFullScreen?.call(fullScreen);
          });
        }
      },
        child: AspectRatio(
          aspectRatio: fullScreen ? 16 / 9 : widget.aspectRatio,
          child: controller.value.isInitialized == false
              ? VideoLoading(loadingStyle: widget.videoLoadingStyle)
              : Stack(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  toggleControls();
                  removeOverlay();
                },
                onDoubleTap: () {
                  togglePlay();
                  removeOverlay();
                },
                onVerticalDragUpdate: (details) {
                  log('Vertical Drag Update${details.delta.dy}');
                  if (details.delta.dy > 0) {
                    if(fullScreen){
                      setState(() {
                        fullScreen = !fullScreen;
                        widget.onFullScreen?.call(fullScreen);
                      });
                    }
                  }
                  else {
                    if(!fullScreen){
                      setState(() {
                        fullScreen = !fullScreen;
                        widget.onFullScreen?.call(fullScreen);
                      });
                    }
                  }
                },
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    color: showMenu
                        ? Colors.black.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: InteractiveViewer(
                    panEnabled: fullScreen? true: false,
                    scaleEnabled: fullScreen? true: false,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              ...videoBuiltInChildren(),
              // forwardRewind(),
            ],
          ),
        ),
    );
  }

  List<Widget> videoBuiltInChildren() {
    return [
      actionBar(),
      liveDirectButton(),
      backbuttonWhenFullScreen(),
      bottomBar(),
      bufferStatus(),
      Visibility(
        visible: !showMenu,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                fullScreen
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 2,
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: false,
                            colors: const VideoProgressColors(
                              playedColor: Color.fromARGB(255, 206, 3, 3),
                              bufferedColor: Color.fromARGB(169, 77, 68, 68),
                              backgroundColor:
                                  Color.fromARGB(27, 255, 255, 255),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
      // m3u8List(),
    ];
  }

  // Widget setAspectRatio(){
  //   return Visibility(
  //     visible: fullScreen && showMenu,
  //
  //   );
  // }

  Widget forwardRewind() {
    return Visibility(
      visible: fullScreen && !showMenu,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                child: const Icon(Icons.fast_rewind,size: 100,color: Colors.transparent,),
                onDoubleTap: () {
                  controller.seekTo(controller.value.position - const Duration(seconds: 10));
                },
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow,size: 100,color: Colors.transparent),
                onPressed: () {
                    toggleControls();
                    removeOverlay();
                },
              ),
              GestureDetector(
                child: const Icon(Icons.fast_forward,size: 100,color: Colors.transparent,),
                onDoubleTap: () {
                  controller.seekTo(controller.value.position + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget backbuttonWhenFullScreen(){
    return Visibility(
      visible: fullScreen && showMenu,
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 10.0, left: 10.0),
          height: 50.0,
          width: 50.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                fullScreen = !fullScreen;
                widget.onFullScreen?.call(fullScreen);;
              });
            },
            child:  const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }

  Widget actionBar() {
    return Visibility(
      visible: showMenu,
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: widget.videoStyle.actionBarPadding ??
                const EdgeInsets.symmetric(
                  horizontal: 0.0,
                  vertical: 0.0,
                ),
            alignment: Alignment.topRight,
            color: widget.videoStyle.actionBarBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => showSettingsDialog(context),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                ),
                SizedBox(
                  width: widget.videoStyle.qualityButtonAndFullScrIcoSpace,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bufferStatus() {
    final bufferedDuration = controller.value.buffered.isNotEmpty
        ? controller.value.buffered.last.end.inSeconds
        : 0;
    final totalDuration = controller.value.duration.inSeconds;
    //get the bitrate from the video controller
    var bitrate = 800;
    final bufferedSizeKB = (bufferedDuration * bitrate) / 1024;
    final totalSizeKB = (totalDuration * bitrate) / 1024;
    return Visibility(
      visible:
          controller.value.isBuffering && controller.value.isCompleted == false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: Container(
            color: Colors.black45,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                'ভিডিও লোড হচ্ছে: ${bufferedSizeKB.toStringAsFixed(0)} KB of ${totalSizeKB.toStringAsFixed(0)} KB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomBar() {
    return Visibility(
      visible: showMenu,
      child: Align(
        alignment: Alignment.center,
        child: PlayerBottomBar(
          hideFullScreenButton: widget.hideFullScreenButton,
          fullScreen: fullScreen,
          controller: controller,
          videoSeek: videoSeek ?? '00:00:00',
          videoDuration: videoDuration ?? '00:00:00',
          videoStyle: widget.videoStyle,
          showBottomBar: showMenu,
          onPlayButtonTap: () => togglePlay(),
          onFastForward: (value) {
            widget.onFastForward?.call(value);
          },
          onRewind: (value) {
            widget.onRewind?.call(value);
          },
          onFullScreen : (){
            setState(() {
              fullScreen = !fullScreen;
              widget.onFullScreen?.call(fullScreen);;
            });
          },
          onFullScreenIconTap: widget.onFullScreenIconTap,
        ),
      ),
    );
  }

  Widget liveDirectButton() {
    return Visibility(
      visible: widget.videoStyle.showLiveDirectButton && showMenu,
      child: Align(
        alignment: Alignment.topLeft,
        child: IntrinsicWidth(
          child: InkWell(
            onTap: () {
              controller.seekTo(controller.value.duration).then((value) {
                widget.onLiveDirectTap?.call(controller.value);
                controller.play();
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 14.0,
              ),
              margin: const EdgeInsets.only(left: 9.0),
              child: Row(
                children: [
                  Container(
                    width: widget.videoStyle.liveDirectButtonSize,
                    height: widget.videoStyle.liveDirectButtonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAtLivePosition
                          ? widget.videoStyle.liveDirectButtonColor
                          : widget.videoStyle.liveDirectButtonDisableColor,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    widget.videoStyle.liveDirectButtonText ?? 'Live',
                    style: widget.videoStyle.liveDirectButtonTextStyle ??
                        const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget m3u8List() {
    RenderBox? renderBox =
        videoQualityKey.currentContext?.findRenderObject() as RenderBox?;
    var offset = renderBox?.localToGlobal(Offset.zero);
    return VideoQualityPicker(
      videoData: m3u8UrlList,
      videoStyle: widget.videoStyle,
      showPicker: m3u8Show,
      positionRight: (renderBox?.size.width ?? 0.0) / 3,
      positionTop: (offset?.dy ?? 0.0) + 35.0,
      onQualitySelected: (data) {
        if (data.dataQuality != m3u8Quality) {
          setState(() {
            m3u8Quality = data.dataQuality ?? m3u8Quality;
          });
          onSelectQuality(data);
        }
        setState(() {
          m3u8Show = false;
        });
        removeOverlay();
      },
      selectedQuality: m3u8Quality,
    );
  }

  void urlCheck(String url) {
    final netRegex = RegExp(RegexResponse.regexHTTP);
    final isNetwork = netRegex.hasMatch(url);
    final uri = Uri.parse(url);
    if (isNetwork) {
      setState(() {
        isOffline = false;
      });
      if (uri.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        widget.onPlayingVideo?.call("MKV");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'mkv',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      }
      else if (uri.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        widget.onPlayingVideo?.call("MP4");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'mp4',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      }
      else if (uri.pathSegments.last.endsWith('webm')) {
        setState(() {
          playType = "WEBM";
        });
        widget.onPlayingVideo?.call("WEBM");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'webm',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      }
      else if (uri.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });
        widget.onPlayingVideo?.call("M3U8");
        videoControlSetup(url);
        getM3U8(url);
      }
      else {
        videoControlSetup(url);
        getM3U8(url);
      }
    } else {
      setState(() {
        isOffline = true;
      });

      videoControlSetup(url);
    }
  }

  void getM3U8(String videoUrl) {
    if (m3u8UrlList.isNotEmpty) {
      m3u8Clean();
    }
    m3u8Video(videoUrl);
  }

  Future<M3U8s?> m3u8Video(String? videoUrl) async {
    m3u8UrlList.add(M3U8Data(dataQuality: "Auto", dataURL: videoUrl));

    RegExp regExp = RegExp(
      RegexResponse.regexM3U8Resolution,
      caseSensitive: false,
      multiLine: true,
    );

    if (m3u8Content != null) {
      setState(() {
        m3u8Content = null;
      });
    }

    if (m3u8Content == null && videoUrl != null) {
      http.Response response =
          await http.get(Uri.parse(videoUrl), headers: widget.headers,
          );
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);

        List<File> cachedFiles = [];
        int index = 0;

        List<RegExpMatch> matches =
            regExp.allMatches(m3u8Content ?? '').toList();

        for (RegExpMatch regExpMatch in matches) {
          String quality = (regExpMatch.group(1)).toString();
          String sourceURL = (regExpMatch.group(3)).toString();
          final netRegex = RegExp(RegexResponse.regexHTTP);
          final netRegex2 = RegExp(RegexResponse.regexURL);
          final isNetwork = netRegex.hasMatch(sourceURL);
          final match = netRegex2.firstMatch(videoUrl);
          String url;
          if (isNetwork) {
            url = sourceURL;
          } else {
            final dataURL = match?.group(0);
            url = "$dataURL$sourceURL";
          }
          for (RegExpMatch regExpMatch2 in matches) {
            String audioURL = (regExpMatch2.group(1)).toString();
            final isNetwork = netRegex.hasMatch(audioURL);
            final match = netRegex2.firstMatch(videoUrl);
            String auURL = audioURL;

            if (!isNetwork) {
              final auDataURL = match!.group(0);
              auURL = "$auDataURL$audioURL";
            }

            audioList.add(AudioModel(url: auURL));
          }

          String audio = "";
          if (audioList.isNotEmpty) {
            audio =
                """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",
                  URI="${audioList.last.url}"\n""";
          } else {
            audio = "";
          }

          if (widget.allowCacheFile) {
            try {
              var file = await FileUtils.cacheFileUsingWriteAsString(
                contents:
                    """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,
                  RESOLUTION=$quality,FRAME-RATE=30.000\n$url""",
                quality: quality,
                videoUrl: url,
              );

              cachedFiles.add(file);

              if (index < matches.length) {
                index++;
              }

              if (widget.allowCacheFile && index == matches.length) {
                widget.onCacheFileCompleted
                    ?.call(cachedFiles.isEmpty ? null : cachedFiles);
              }
            } catch (e) {
              widget.onCacheFileFailed?.call(e);
            }
          }
          //need to add the video quality to the list by the quality order.and auto quality should be the first one.
          //  var orderBasedSerializedList = m3u8UrlList.map((e) => e.dataQuality).toList();
          m3u8UrlList.add(M3U8Data(dataQuality: quality, dataURL: url));
        }
        M3U8s m3u8s = M3U8s(m3u8s: m3u8UrlList);

        return m3u8s;
      }
    }

    return null;
  }

  void videoControlSetup(String? url) async {
    videoInit(url);
    controller.addListener(listener);
    if (widget.displayFullScreenAfterInit) {
      setState(() {
        fullScreen = true;
      });
      widget.onFullScreen?.call(fullScreen);
    }
    if (widget.autoPlayVideoAfterInit) {
      controller.play();
    }
    widget.onVideoInitCompleted?.call(controller);
  }

  void listener() async {
    if (widget.videoStyle.showLiveDirectButton) {
      if (controller.value.position != controller.value.duration) {
        if (isAtLivePosition) {
          setState(() {
            isAtLivePosition = false;
          });
        }
      } else {
        if (!isAtLivePosition) {
          setState(() {
            isAtLivePosition = true;
          });
        }
      }
    }

    if (controller.value.isInitialized && controller.value.isPlaying) {
      if (!await WakelockPlus.enabled) {
        await WakelockPlus.enable();
      }

      setState(() {
        videoDuration = controller.value.duration.convertDurationToString();
        videoSeek = controller.value.position.convertDurationToString();
        videoSeekSecond = controller.value.position.inSeconds.toDouble();
        videoDurationSecond = controller.value.duration.inSeconds.toDouble();
      });
    } else {
      if (await WakelockPlus.enabled) {
        await WakelockPlus.disable();
        setState(() {});
      }
    }
  }

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(const Duration(milliseconds: 5000), () {
      // if (controller != null && controller.value.isPlaying) {
      if (controller.value.isPlaying) {
        if (showMenu && mounted) {
          setState(() {
            showMenu = false;
            m3u8Show = false;
            controlBarAnimationController.reverse();
            widget.onShowMenu?.call(showMenu, m3u8Show);
            removeOverlay();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu) {
      setState(() {
        showMenu = true;
      });
      widget.onShowMenu?.call(showMenu, m3u8Show);

      createHideControlBarTimer();
    } else {
      setState(() {
        m3u8Show = false;
        showMenu = false;
      });

      widget.onShowMenu?.call(showMenu, m3u8Show);
    }
    // setState(() {
    if (showMenu) {
      controlBarAnimationController.forward();
    } else {
      controlBarAnimationController.reverse();
    }
    // });
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller.value.isPlaying) {
      controller.pause().then((_) {
        widget.onPlayButtonTap?.call(controller.value.isPlaying);
      });
    } else {
      controller.play().then((_) {
        widget.onPlayButtonTap?.call(controller.value.isPlaying);
      });
    }
    setState(() {});
  }

  void videoInit(String? url) {
    if (isOffline == false) {
      if (playType == "MP4" || playType == "WEBM") {
        // Play MP4 and WEBM video
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.other,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((value) => seekToLastPlayingPosition);
      } else if (playType == "MKV") {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.dash,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((value) => seekToLastPlayingPosition);
      } else if (playType == "HLS") {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.hls,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((_) {
            setState(() => hasInitError = false);
            seekToLastPlayingPosition();
          }).catchError((e) {
            setState(() => hasInitError = true);
          });
      }
    }
    else {
      hideQualityList = true;
      controller = VideoPlayerController.file(
        File(url!),
        closedCaptionFile: widget.closedCaptionFile,
        videoPlayerOptions: widget.videoPlayerOptions,
      )..initialize().then((value) {
          setState(() => hasInitError = false);
          seekToLastPlayingPosition();
        }).catchError((e) {
          setState(() => hasInitError = true);
        });
    }
  }

  void _navigateLocally(context) async {
    if (!fullScreen) {
      if (ModalRoute.of(context)?.willHandlePopInternally ?? false) {
        Navigator.of(context).pop();
      }
      return;
    }

    ModalRoute.of(context)?.addLocalHistoryEntry(
      LocalHistoryEntry(
        onRemove: () {
          if (fullScreen) ScreenUtils.toggleFullScreen(fullScreen);
        },
      ),
    );
  }

  void onSelectQuality(M3U8Data data) async {
    lastPlayedPos = await controller.position;
    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {
        String text;
        var file = await FileUtils.readFileFromPath(
            videoUrl: data.dataURL ?? '', quality: data.dataQuality ?? '');
        if (file != null) {
          if (kDebugMode) {
          }
          text = await file.readAsString();
          if (kDebugMode) {
          }
          // videoControlSetup(file);
        }
        if (data.dataURL != null) {
          playLocalM3U8File(data.dataURL!);
        } else {
          if (kDebugMode) {
          }
        }
      } catch (e) {
        if (kDebugMode) {
        }
      }
    }
  }

  void playLocalM3U8File(String url) {
    controller.dispose();
    controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      closedCaptionFile: widget.closedCaptionFile,
      videoPlayerOptions: widget.videoPlayerOptions,
      httpHeaders: widget.headers ?? const <String, String>{},
    )..initialize().then((_) {
        setState(() => hasInitError = false);
        seekToLastPlayingPosition();
        controller.play();
      }).catchError((e) {
        setState(() => hasInitError = true);
      });

    controller.addListener(listener);
    controller.play();
  }

  void m3u8Clean() async {
    for (int i = 2; i < m3u8UrlList.length; i++) {
      try {
        var file = await FileUtils.readFileFromPath(
            videoUrl: m3u8UrlList[i].dataURL ?? '',
            quality: m3u8UrlList[i].dataQuality ?? '');
        var exists = await file?.exists();
        if (exists ?? false) {
          await file?.delete();
        }
      } catch (e) {
        rethrow;
      }
    }
    try {
      audioList.clear();
    } catch (e) {
      rethrow;
    }
    audioList.clear();
    try {
      m3u8UrlList.clear();
    } catch (e) {
      rethrow;
    }
  }

  void showOverlay() {
    setState(() {
      overlayEntry = OverlayEntry(
        builder: (_) => m3u8List(),
      );
      Overlay.of(context).insert(overlayEntry!);
    });
  }

  void showResolutionDialog(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 10.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 10.0),
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Text(''),
                    )),
                VideoQualityPicker(
                  videoData: m3u8UrlList,
                  videoStyle: widget.videoStyle,
                  showPicker: true,
                  onQualitySelected: (data) {
                    if (data.dataQuality != m3u8Quality) {

                      setState(() {
                        m3u8Quality = data.dataQuality ?? m3u8Quality;
                      });
                      onSelectQuality(data);
                    }
                    setState(() {
                      m3u8Show = false;
                    });
                    // removeOverlay();
                    Navigator.pop(context);
                  },
                  selectedQuality: m3u8Quality,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPlayBackSpeed(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 10.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 10.0),
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Text(''),
                    )),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      playbackSpeeds.length,
                      (index) => ListTile(
                            leading: Icon(
                              Icons.check,
                              color: playbackSpeeds[index] == playbackSpeed
                                  ? Colors.green
                                  : Colors.transparent,
                              size: 20,
                            ),
                            title: Text(
                              playbackSpeeds[index] == 1.0
                                  ? 'Normal'
                                  : '${playbackSpeeds[index]}x',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              setState(() {
                                playbackSpeed = playbackSpeeds[index];
                              });
                              onPlayBackSpeedChange(
                                  setPlaybackSpeed: playbackSpeed);
                              Navigator.pop(context);
                            },
                          )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onPlayBackSpeedChange({required double setPlaybackSpeed}) {
    if (controller.value.isPlaying) {
      controller.pause();
      controller.setPlaybackSpeed(setPlaybackSpeed);
      controller.play();
    } else {
      controller.setPlaybackSpeed(setPlaybackSpeed);
      controller.play();
    }
  }

  Future showSettingsDialog(BuildContext context) {
    return showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) {
          duration = controller.value.duration;
          return Container(
            margin: const EdgeInsets.only(top: 10.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 10.0),
                      width: 70,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Text(''),
                    )),
                if (!hideQualityList)
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: const Text(
                      "Quality",
                      style: TextStyle(fontSize: 14.0, color: Colors.black),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            m3u8Quality.toString() == 'Auto'
                                ? 'Auto'
                                : '${m3u8Quality.toString().split('x').last}p',
                            style: const TextStyle(
                                fontSize: 12.0, color: Colors.black54)),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showResolutionDialog(context);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.slow_motion_video),
                  title: const Text(
                    "Speed",
                    style: TextStyle(fontSize: 14.0, color: Colors.black),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        playbackSpeed == 1.0 ? 'Normal' : '${playbackSpeed}x',
                        style: const TextStyle(
                            fontSize: 12.0, color: Colors.black54),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showPlayBackSpeed(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    loop ? Icons.repeat_one : Icons.repeat,
                  ),
                  title: const Text(
                    "Loop Video",
                    style: TextStyle(fontSize: 14.0, color: Colors.black),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        loop ? 'On' : 'Off',
                        style: const TextStyle(
                            fontSize: 12.0, color: Colors.black54),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 15),
                    ],
                  ),
                  onTap: () {
                    loop = !loop;
                    if (controller.value.isPlaying) {
                      controller.pause();
                      controller.setLooping(loop);
                      controller.play();
                    } else {
                      controller.setLooping(loop);
                    }
                    if (loop) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Video loop is on"),
                          duration: Duration(seconds: 3),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Video loop is off"),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.grey,
                      ));
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  void removeOverlay() {
    setState(() {
      overlayEntry?.remove();
      overlayEntry = null;
    });
  }

  void seekToLastPlayingPosition() {
    controller.setPlaybackSpeed(playbackSpeed);
    if (lastPlayedPos != null) {
      controller.seekTo(lastPlayedPos!);
      widget.onVideoInitCompleted?.call(controller);
      lastPlayedPos = null;
    }
  }
}
