import '../errors/app_exception.dart';

class ApiException extends AppException {
  const ApiException(super.message, {super.code});
}
