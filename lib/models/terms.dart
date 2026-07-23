class TermsModel {
  final String terms;
  final String privacy;
  final String aboutus;

  TermsModel({
    required this.terms,
    required this.privacy,
    required this.aboutus,
  });

  factory TermsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return TermsModel(
      terms: data['terms']?.toString() ?? '',
      privacy: data['privacy']?.toString() ?? '',
      aboutus: data['aboutus']?.toString() ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'terms': terms,
      'privacy': privacy,
      'aboutus': aboutus,
    };
  }
}