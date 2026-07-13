/// A survey as shown in the list. The full questionnaire definition is not
/// carried here — it is stored in Drift on download and read by the
/// questionnaire engine later.
class Survey {
  const Survey({
    required this.remoteId,
    required this.title,
    required this.version,
    this.isDownloaded = false,
  });

  final String remoteId;
  final String title;
  final int version;

  /// True when the definition is cached locally (available offline).
  final bool isDownloaded;

  Survey copyWith({bool? isDownloaded}) => Survey(
        remoteId: remoteId,
        title: title,
        version: version,
        isDownloaded: isDownloaded ?? this.isDownloaded,
      );
}
