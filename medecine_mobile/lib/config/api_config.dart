class ApiConfig {
  // Avec adb reverse tcp:8080 tcp:8080 sur téléphone USB,
  // 127.0.0.1:8080 pointe directement vers le serveur FastAPI du PC.
  static const String baseUrl = 'http://127.0.0.1:8080';

  static const String medicamentsEndpoint = '$baseUrl/medicaments/';
  static const String askEndpoint = '$baseUrl/assistant/ask';
  static const String scanEndpoint = '$baseUrl/assistant/scan';
  static const String evaluationEndpoint = '$baseUrl/evaluation/run';
}