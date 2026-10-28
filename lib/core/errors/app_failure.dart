class AppFailure {
  final String message;
  final String? code;

  const AppFailure(this.message, {this.code});

  @override
  String toString() => 'AppFailure(message: $message, code: $code)';
}
