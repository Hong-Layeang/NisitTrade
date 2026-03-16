String buildSchoolShortName({
  String? universityName,
  String? universityDomain,
  String? email,
  String fallback = '',
}) {
  final fromName = _fromUniversityName(universityName);
  if (fromName.isNotEmpty) return fromName;

  final fromDomain = _fromDomain(universityDomain);
  if (fromDomain.isNotEmpty) return fromDomain;

  final fromEmailDomain = _fromEmail(email);
  if (fromEmailDomain.isNotEmpty) return fromEmailDomain;

  return fallback;
}

String _fromEmail(String? email) {
  if (email == null || email.trim().isEmpty) return '';
  final parts = email.split('@');
  if (parts.length < 2) return '';
  return _fromDomain(parts[1]);
}

String _fromUniversityName(String? universityName) {
  if (universityName == null || universityName.trim().isEmpty) return '';

  const skipWords = {'of', 'the', 'and', 'in', 'at', 'for', 'a', 'an', 'to'};
  final parts = universityName.trim().split(RegExp(r'\s+'));
  final initials = parts
      .where((w) => w.isNotEmpty && !skipWords.contains(w.toLowerCase()))
      .map((w) => w[0].toLowerCase())
      .join();
  return initials;
}

String _fromDomain(String? domain) {
  if (domain == null || domain.trim().isEmpty) return '';

  const excluded = {
    'student',
    'students',
    'mail',
    'www',
    'edu',
    'ac',
    'com',
    'org',
    'net',
    'kh',
  };

  final parts = domain.toLowerCase().split('.').where((p) => p.isNotEmpty);
  final meaningful = parts.where((p) => !excluded.contains(p));
  if (meaningful.isNotEmpty) return meaningful.first;
  return '';
}
