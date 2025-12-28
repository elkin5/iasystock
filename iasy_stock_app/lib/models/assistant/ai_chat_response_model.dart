class AiChatResponseModel {
  const AiChatResponseModel({
    required this.message,
    this.sessionId,
    this.data,
    required this.suggestions,
    this.timestamp,
  });

  factory AiChatResponseModel.fromJson(Map<String, dynamic> json) {
    final timestampList = json['timestamp'];
    DateTime? timestamp;

    if (timestampList is List && timestampList.length >= 3) {
      final year = timestampList[0] as int? ?? 0;
      final month = timestampList[1] as int? ?? 1;
      final day = timestampList[2] as int? ?? 1;
      final hour = timestampList.length > 3 ? timestampList[3] as int? ?? 0 : 0;
      final minute =
          timestampList.length > 4 ? timestampList[4] as int? ?? 0 : 0;
      final second =
          timestampList.length > 5 ? timestampList[5] as int? ?? 0 : 0;

      final rawMicrosecond =
          timestampList.length > 6 ? timestampList[6] as int? ?? 0 : 0;
      final millisecond = rawMicrosecond ~/ 1000;
      final microsecond = rawMicrosecond % 1000;

      timestamp = DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );
    }

    return AiChatResponseModel(
      message: json['message'] as String? ?? '',
      sessionId: json['sessionId'] as String?,
      data: json['data'],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      timestamp: timestamp,
    );
  }

  final String message;
  final String? sessionId;
  final dynamic data;
  final List<String> suggestions;
  final DateTime? timestamp;
}
