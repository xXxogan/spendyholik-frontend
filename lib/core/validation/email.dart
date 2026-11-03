// Только форма адреса: настоящую проверку делает сервер письмом.
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String value) => _email.hasMatch(value.trim());
