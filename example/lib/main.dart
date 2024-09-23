import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ns_player/ns_player.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: fullscreen == false
            ? null
            : null,
        body: Padding(
          padding: fullscreen
              ? EdgeInsets.zero
              : const EdgeInsets.only(top: 32.0),
          child: NsPlayer(
            aspectRatio: 16 / 9,
            url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
            headers: const {'Referer': 'https://www.google.com'},
            allowCacheFile: true,
            autoPlayVideoAfterInit: true,
            onCacheFileCompleted: (files) {
              if (kDebugMode) {
                print('Cached file length ::: ${files?.length}');
              }

              if (files != null && files.isNotEmpty) {
                for (var file in files) {
                  if (kDebugMode) {
                    print('File path ::: ${file.path}');
                  }
                }
              }
            },
            onCacheFileFailed: (error) {
              if (kDebugMode) {
                print('Cache file error ::: $error');
              }
            },
            videoStyle: const VideoStyle(
              qualityStyle: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              forwardAndBackwardBtSize: 30.0,
              playButtonIconSize: 50.0,
              // playIcon: Icon(
              //   Icons.play_arrow_outlined,
              //   size: 45.0,
              //   color: Colors.white,
              // ),
              // pauseIcon: Icon(
              //   Icons.pause_outlined,
              //   size: 45.0,
              //   color: Colors.white,
              // ),
              videoQualityPadding: EdgeInsets.all(5.0),
              // showLiveDirectButton: true,
              enableSystemOrientationsOverride: true,
            ),
            videoLoadingStyle: const VideoLoadingStyle(
              loading: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('image/yoyo_logo.png'),
                      fit: BoxFit.fitHeight,
                      height: 50,
                    ),
                    SizedBox(height: 16.0),
                    Text("Loading video..."),
                  ],
                ),
              ),
            ),
            onFullScreen: (value) {
              setState(() {
                if (fullscreen != value) {
                  fullscreen = value;
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
