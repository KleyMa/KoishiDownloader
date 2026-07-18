package com.example.music_downloader

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.withLock
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import com.yausername.ffmpeg.FFmpeg
import android.content.Intent

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "YtDlpNative"
        private const val METHOD_CHANNEL = "com.example.music_downloader/ytdlp"
        private const val EVENT_CHANNEL = "com.example.music_downloader/download_progress"
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Update the intent so getSharedText reads the new one
        if (Intent.ACTION_SEND == intent.action && "text/plain" == intent.type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            // Send it directly to flutter via channel if possible or let flutter poll.
            // Since we rely on flutter polling on init/resume, setting the intent is enough 
            // if flutter handles AppLifecycleState.resumed.
        }
    }

    private val activeJobs = ConcurrentHashMap<String, Job>()
    private val progressMap = ConcurrentHashMap<String, Map<String, Any?>>()
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var ytDlpInitialized = false
    private val initMutex = kotlinx.coroutines.sync.Mutex()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up EventChannel for download progress streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.channel.shared.data").setMethodCallHandler { call, result ->
            if (call.method == "getSharedText") {
                val intent = intent
                val action = intent?.action
                val type = intent?.type

                if (Intent.ACTION_SEND == action && "text/plain" == type) {
                    val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                    // Clear the intent so it doesn't get processed again
                    intent.action = Intent.ACTION_MAIN
                    intent.removeExtra(Intent.EXTRA_TEXT)
                    result.success(sharedText)
                } else {
                    result.success(null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "initYtDlp" -> handleInitYtDlp(result)
                    "updateYtDlp" -> handleUpdateYtDlp(result)
                    "getVideoInfo" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("INVALID_ARGS", "URL is required", null)
                        } else {
                            handleGetVideoInfo(url, result)
                        }
                    }
                    "getPlaylistInfo" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("INVALID_ARGS", "URL is required", null)
                        } else {
                            handleGetPlaylistInfo(url, result)
                        }
                    }
                    "startDownload" -> {
                        val url = call.argument<String>("url")
                        val format = call.argument<String>("format")
                        val quality = call.argument<String>("quality")
                        val outputPath = call.argument<String>("outputPath")
                        val taskId = call.argument<String>("taskId")
                        if (url == null || format == null || quality == null || outputPath == null || taskId == null) {
                            result.error("INVALID_ARGS", "url, format, quality, outputPath, and taskId are required", null)
                        } else {
                            handleStartDownload(url, format, quality, outputPath, taskId, result)
                        }
                    }
                    "cancelDownload" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId == null) {
                            result.error("INVALID_ARGS", "taskId is required", null)
                        } else {
                            handleCancelDownload(taskId, result)
                        }
                    }
                    "getProgress" -> {
                        val taskId = call.argument<String>("taskId")
                        if (taskId == null) {
                            result.error("INVALID_ARGS", "taskId is required", null)
                        } else {
                            handleGetProgress(taskId, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Ensures YoutubeDL and FFmpeg are initialized exactly once.
     * Safe to call from multiple coroutines — uses a mutex to prevent races.
     * If already initialized, returns immediately.
     */
    private suspend fun ensureInitialized() {
        if (ytDlpInitialized) return
        initMutex.withLock {
            // Double-check after acquiring lock
            if (ytDlpInitialized) return
            Log.d(TAG, "Starting YoutubeDL initialization...")
            Log.d(TAG, "App files dir: ${application.filesDir.absolutePath}")
            Log.d(TAG, "App native lib dir: ${application.applicationInfo.nativeLibraryDir}")
            try {
                YoutubeDL.getInstance().init(application)
                Log.d(TAG, "YoutubeDL initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "YoutubeDL.init() FAILED", e)
                throw e
            }
            try {
                FFmpeg.getInstance().init(application)
                Log.d(TAG, "FFmpeg initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "FFmpeg.init() FAILED", e)
                throw e
            }
            ytDlpInitialized = true
            Log.d(TAG, "All initialization complete")
        }
    }

    private fun handleInitYtDlp(result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                ensureInitialized()
                Log.i(TAG, "handleInitYtDlp: SUCCESS")
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                Log.e(TAG, "handleInitYtDlp: FAILED", e)
                mainHandler.post {
                    result.error("INIT_ERROR", "Failed to initialize yt-dlp: ${e.message}", e.stackTraceToString())
                }
            }
        }
    }

    private fun handleUpdateYtDlp(result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                val status = YoutubeDL.getInstance().updateYoutubeDL(application)
                mainHandler.post {
                    result.success(
                        when (status) {
                            YoutubeDL.UpdateStatus.DONE -> "updated"
                            YoutubeDL.UpdateStatus.ALREADY_UP_TO_DATE -> "already_up_to_date"
                            else -> "unknown"
                        }
                    )
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("UPDATE_ERROR", "Failed to update yt-dlp: ${e.message}", e.stackTraceToString())
                }
            }
        }
    }

    private fun handleGetVideoInfo(url: String, result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                ensureInitialized()
                Log.d(TAG, "getVideoInfo: fetching info for $url")
                val request = YoutubeDLRequest(url)
                request.addOption("--dump-json")
                request.addOption("--no-playlist")
                // Bypass YouTube bot detection / 429 errors
                request.addOption("--extractor-args", "youtube:player_client=ios,android")
                val videoInfo = YoutubeDL.getInstance().getInfo(request)

                val formatsListRaw = videoInfo.formats
                val formatsList = mutableListOf<Map<String, Any?>>()
                if (formatsListRaw != null) {
                    for (f in formatsListRaw) {
                        formatsList.add(
                            mapOf(
                                "formatId" to (f.formatId ?: ""),
                                "ext" to (f.ext ?: ""),
                                "resolution" to ("${f.width ?: 0}x${f.height ?: 0}"),
                                "filesize" to (f.fileSize),
                                "acodec" to (f.acodec ?: "none"),
                                "vcodec" to (f.vcodec ?: "none"),
                                "abr" to (f.abr)
                            )
                        )
                    }
                }

                val infoMap = mapOf<String, Any?>(
                    "title" to (videoInfo.title ?: "Unknown"),
                    "thumbnail" to (videoInfo.thumbnail ?: ""),
                    "duration" to (videoInfo.duration),
                    "url" to url,
                    "formats" to formatsList
                )

                mainHandler.post { result.success(infoMap) }
            } catch (e: Exception) {
                Log.e(TAG, "getVideoInfo FAILED for $url", e)
                mainHandler.post {
                    result.error("INFO_ERROR", "Failed to get video info: ${e.message}", e.stackTraceToString())
                }
            }
        }
    }

    private fun handleGetPlaylistInfo(url: String, result: MethodChannel.Result) {
        coroutineScope.launch(Dispatchers.IO) {
            try {
                ensureInitialized()
                val request = YoutubeDLRequest(url)
                request.addOption("--flat-playlist")
                request.addOption("--dump-json")

                val response = YoutubeDL.getInstance().execute(request)
                val output = response.out ?: ""

                // Each line of output is a JSON object for one video
                val videoEntries = mutableListOf<Map<String, Any?>>()
                val lines = output.split("\n").filter { it.isNotBlank() }

                for (line in lines) {
                    try {
                        val json = org.json.JSONObject(line)
                        videoEntries.add(
                            mapOf(
                                "title" to json.optString("title", "Unknown"),
                                "thumbnail" to json.optString("thumbnail", ""),
                                "duration" to json.optDouble("duration", 0.0),
                                "url" to json.optString("url", json.optString("webpage_url", "")),
                                "id" to json.optString("id", "")
                            )
                        )
                    } catch (jsonEx: Exception) {
                        // Skip malformed entries
                    }
                }

                mainHandler.post { result.success(videoEntries) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("PLAYLIST_ERROR", "Failed to get playlist info: ${e.message}", e.stackTraceToString())
                }
            }
        }
    }

    private fun handleStartDownload(
        url: String,
        format: String,
        quality: String,
        outputPath: String,
        taskId: String,
        result: MethodChannel.Result
    ) {
        Log.d(TAG, "handleStartDownload: taskId=$taskId, url=$url, format=$format, quality=$quality, outputPath=$outputPath")

        val job = coroutineScope.launch(Dispatchers.IO) {
            try {
                ensureInitialized()
                val request = YoutubeDLRequest(url)

                // Set output template
                request.addOption("-o", "$outputPath/%(title)s.%(ext)s")
                // Bypass YouTube bot detection / 429 errors
                request.addOption("--extractor-args", "youtube:player_client=ios,android")

                // Configure format-specific options
                when (format.lowercase()) {
                    "mp4" -> {
                        val heightLimit = quality.replace("p", "").trim()
                        request.addOption("-f", "bestvideo[height<=$heightLimit]+bestaudio/best[height<=$heightLimit]")
                        request.addOption("--merge-output-format", "mp4")
                    }
                    "mp3" -> {
                        request.addOption("-x")
                        request.addOption("--audio-format", "mp3")
                        // Map quality string to yt-dlp audio quality values
                        val audioQuality = when (quality.lowercase()) {
                            "best", "320k", "320" -> "0"
                            "256k", "256" -> "1"
                            "192k", "192" -> "2"
                            "160k", "160" -> "3"
                            "128k", "128" -> "5"
                            "96k", "96" -> "6"
                            "64k", "64" -> "8"
                            "worst" -> "9"
                            else -> "0"
                        }
                        request.addOption("--audio-quality", audioQuality)
                    }
                    else -> {
                        // Default: best available
                        request.addOption("-f", "best")
                    }
                }

                // Don't overwrite existing files (for yt-dlp downloader)
                request.addOption("--no-overwrites")
                // Force FFmpeg to overwrite without prompting, avoiding infinite hangs
                request.addOption("--postprocessor-args", "ffmpeg:-y")

                // Send initial progress
                Log.d(TAG, "handleStartDownload: sending starting event")
                sendProgressEvent(taskId, 0.0f, "starting", "Starting download...")

                Log.d(TAG, "handleStartDownload: executing YoutubeDL request...")
                YoutubeDL.getInstance().execute(
                    request,
                    taskId
                ) { progress: Float, _: Long, line: String? ->
                    if (!isActive) return@execute
                    Log.d(TAG, "handleStartDownload: progress=$progress, line=$line")
                    progressMap[taskId] = mapOf(
                        "taskId" to taskId,
                        "progress" to progress.toDouble(),
                        "status" to "downloading",
                        "line" to (line ?: "")
                    )
                    sendProgressEvent(taskId, progress, "downloading", line ?: "")
                }

                // Download completed
                Log.d(TAG, "handleStartDownload: YoutubeDL.execute completed successfully")
                
                // Scan the output directory to ensure files appear in Gallery/File Managers
                try {
                    val dir = java.io.File(outputPath)
                    if (dir.exists() && dir.isDirectory) {
                        val filesToScan = dir.listFiles()?.map { it.absolutePath }?.toTypedArray()
                        if (!filesToScan.isNullOrEmpty()) {
                            android.media.MediaScannerConnection.scanFile(
                                this@MainActivity,
                                filesToScan,
                                null,
                                null
                            )
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to scan files in $outputPath", e)
                }

                progressMap[taskId] = mapOf(
                    "taskId" to taskId,
                    "progress" to 100.0,
                    "status" to "completed",
                    "line" to "Download completed"
                )
                sendProgressEvent(taskId, 100.0f, "completed", "Download completed")

            } catch (e: CancellationException) {
                progressMap[taskId] = mapOf(
                    "taskId" to taskId,
                    "progress" to 0.0,
                    "status" to "cancelled",
                    "line" to "Download cancelled"
                )
                sendProgressEvent(taskId, 0.0f, "cancelled", "Download cancelled")
            } catch (e: Exception) {
                Log.e(TAG, "handleStartDownload FAILED for $url", e)
                progressMap[taskId] = mapOf(
                    "taskId" to taskId,
                    "progress" to 0.0,
                    "status" to "error",
                    "line" to (e.message ?: "Unknown error")
                )
                sendProgressEvent(taskId, 0.0f, "error", e.message ?: "Unknown error")
            } finally {
                activeJobs.remove(taskId)
            }
        }

        activeJobs[taskId] = job
        result.success(taskId)
    }

    private fun sendProgressEvent(taskId: String, progress: Float, status: String, line: String) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "taskId" to taskId,
                    "progress" to progress.toDouble(),
                    "status" to status,
                    "line" to line
                )
            )
        }
    }

    private fun handleCancelDownload(taskId: String, result: MethodChannel.Result) {
        val job = activeJobs[taskId]
        if (job != null) {
            job.cancel()
            YoutubeDL.getInstance().destroyProcessById(taskId)
            activeJobs.remove(taskId)
            result.success(true)
        } else {
            result.error("NOT_FOUND", "No active download found for taskId: $taskId", null)
        }
    }

    private fun handleGetProgress(taskId: String, result: MethodChannel.Result) {
        val progress = progressMap[taskId]
        if (progress != null) {
            result.success(progress)
        } else {
            result.success(
                mapOf(
                    "taskId" to taskId,
                    "progress" to 0.0,
                    "status" to "unknown",
                    "line" to "No progress information available"
                )
            )
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Cancel all active downloads
        activeJobs.values.forEach { it.cancel() }
        activeJobs.clear()
        progressMap.clear()
        coroutineScope.cancel()
    }
}
