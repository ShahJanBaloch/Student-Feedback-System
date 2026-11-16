class CampaignTargetReport {
  const CampaignTargetReport({
    required this.targetId,
    required this.campaignTitle,
    required this.subjectName,
    required this.className,
    required this.status,
    required this.threshold,
    required this.responseCount,
    required this.criteria,
    required this.publishedComments,
    required this.disclaimer,
  });

  final String targetId;
  final String campaignTitle;
  final String subjectName;
  final String className;
  final String status;
  final int threshold;
  final int? responseCount;
  final List<CampaignCriterionReport> criteria;
  final List<String> publishedComments;
  final String disclaimer;

  bool get isBelowThreshold => status == 'below_threshold';

  factory CampaignTargetReport.fromMap({
    required String targetId,
    required String campaignTitle,
    required String subjectName,
    required String className,
    required Map<String, dynamic> map,
  }) {
    final criteria = map['criteria'] as List<dynamic>? ?? const [];
    final comments = map['published_comments'] as List<dynamic>? ?? const [];

    return CampaignTargetReport(
      targetId: targetId,
      campaignTitle: campaignTitle,
      subjectName: subjectName,
      className: className,
      status: map['status'] as String? ?? 'below_threshold',
      threshold: (map['threshold'] as num?)?.toInt() ?? 0,
      responseCount: (map['response_count'] as num?)?.toInt(),
      criteria: criteria
          .map(
            (item) => CampaignCriterionReport.fromMap(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      publishedComments: comments
          .map((item) => (item as Map<String, dynamic>)['body'] as String)
          .toList(),
      disclaimer: map['disclaimer'] as String? ?? '',
    );
  }
}

class CampaignCriterionReport {
  const CampaignCriterionReport({
    required this.category,
    required this.title,
    required this.meanRating,
    required this.numericResponses,
    required this.notApplicableCount,
  });

  final String category;
  final String title;
  final double? meanRating;
  final int numericResponses;
  final int notApplicableCount;

  factory CampaignCriterionReport.fromMap(Map<String, dynamic> map) {
    return CampaignCriterionReport(
      category: map['category'] as String? ?? '',
      title: map['title'] as String? ?? '',
      meanRating: (map['mean_rating'] as num?)?.toDouble(),
      numericResponses: (map['numeric_responses'] as num?)?.toInt() ?? 0,
      notApplicableCount: (map['na_count'] as num?)?.toInt() ?? 0,
    );
  }
}
