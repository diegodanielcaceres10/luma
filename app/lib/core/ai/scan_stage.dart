/// Steps of reading an image with the AI service that the app can tell apart.
enum ScanStage {
  /// Encoding the image so it can be sent.
  preparing,

  /// The request is out. Sending it and waiting for the answer are a single
  /// call, so they are one stage.
  sending,

  /// The answer arrived and is being checked and read.
  processing,
}

/// Called by a scan each time it moves on to [stage].
typedef ScanProgress = void Function(ScanStage stage);
