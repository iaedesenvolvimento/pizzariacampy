class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Não foi possível conectar ao servidor.'})
      : super(code: 'NETWORK_ERROR');
}

class ApiException extends AppException {
  const ApiException({required super.message, super.code, required this.statusCode});

  final int statusCode;
}
