class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime expiry;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
  });
}