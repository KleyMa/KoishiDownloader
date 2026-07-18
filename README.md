# Koishi Downloader

A mobile application built with **Flutter** for downloading media content (Audio and Video) quickly and easily from multiple platforms (YouTube, etc.). It is powered by the combined capabilities of **yt-dlp** and **FFmpeg**.

## Overview
Koishi Downloader is a tool that allows you to extract and save videos or music directly to your device, processing the files in the best possible quality. Thanks to yt-dlp, the app is able to automatically detect links from almost any social network without the need for you to manually select the platform.

## Main Features

- **Smart Link Detection:** Paste a video link and the app will automatically detect the platform.
- **Playlist Support:** Want to download an album or a full YouTube playlist? The app can process entire playlists and add them to the download queue.
- **Customizable Formats and Qualities:** 
  - **Audio (MP3):** Select the bitrate quality (128kbps, 192kbps, 320kbps, etc.) for your music.
  - **Video (MP4):** Select the desired resolution (360p, 720p, 1080p) when downloading audiovisual content.
- **Download Manager (Queue):** The application features an interactive queue where you can **pause, resume, or cancel** any ongoing download.
- **Progress Notifications:** Keep track of the download and conversion of your files through real-time notifications, even in the background.
- **Customizable Directories:** Choose exactly which folder on your device you want to save music in, and which one for videos.
- **Bilingual Support:** Interface available in **English** and **Spanish**.

## Technologies and Architecture

This project is built with an advanced and scalable design:
- **Framework:** Flutter (Android / iOS).
- **Core Engines:** 
  - `yt-dlp` (Via native/platform channels).
  - `ffmpeg_kit_flutter_new` (For extraction and MP3 conversion).
- **State Management:** [Riverpod](https://riverpod.dev/) (`riverpod_annotation` and `flutter_riverpod`).
- **Architecture:** Feature-Driven Architecture (Divided into `/core`, `/features`, `/navigation`).
- **Localization:** `easy_localization`.
- **UI Design:** Premium dark theme, smooth micro-animations, gradient usage, and *glassmorphism*.