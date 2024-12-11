// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static io.flutter.plugins.videoplayer.DeviceUtils.isLowEndDevice;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MimeTypes;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.exoplayer.source.MediaSource;

final class LocalVideoAsset extends VideoAsset {
  LocalVideoAsset(@NonNull String assetUrl) {
    super(assetUrl);
  }

  @NonNull
  @Override
  MediaItem getMediaItem() {
    return new MediaItem.Builder().setUri(assetUrl)
            .setMimeType(getMimeType())
            .build();
  }


  private String getMimeType() {
    boolean isLowEnd = isLowEndDevice();
    return isLowEnd ? MimeTypes.VIDEO_H264 : null;
  }


  @Override
  MediaSource.Factory getMediaSourceFactory(Context context) {
    return new DefaultMediaSourceFactory(context);
  }
}
