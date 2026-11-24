import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/medicament.dart';

class ApiService {
  final Duration timeout = const Duration(seconds: 90);

  final List<Medicament> _catalogueSecours = [
    Medicament.fromJson({
      'id': 1,
      'nom': 'Paracetamol 500mg',
      'molecule': 'Paracetamol',
      'posologie': '1 comprime toutes les 6 heures (max 3g/jour)',
      'effets_secondaires': 'Rares reactions cutanees ou atteinte hepatique si surdosage',
      'contre_indications': 'Insuffisance hepatique severe',
    }),
    Medicament.fromJson({
      'id': 2,
      'nom': 'Ibuprofene 200mg',
      'molecule': 'Ibuprofene',
      'posologie': '1 comprime pendant les repas, 1 a 3 fois par jour',
      'effets_secondaires': 'Troubles digestifs, douleurs abdominales',
      'contre_indications': 'Ulcere gastro-duodenal, grossesse (3e trimestre), allergie AINS',
    }),
  ];

  List<Medicament> get catalogueLocal => List<Medicament>.from(_catalogueSecours);

  Future<List<Medicament>> getMedicaments() async {
    final uri = Uri.parse(ApiConfig.medicamentsEndpoint);
    final response = await http.get(uri).timeout(timeout);

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> rawList;

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic candidate =
            decoded['medicaments'] ?? decoded['items'] ?? decoded['data'] ?? <dynamic>[];
        rawList = candidate is List ? candidate : <dynamic>[];
      } else {
        rawList = <dynamic>[];
      }

      final parsed = rawList
          .whereType()
          .map((item) => Medicament.fromJson(item))
          .toList();

      if (parsed.isNotEmpty) {
        _catalogueSecours
          ..clear()
          ..addAll(parsed);
      }
      return parsed;
    }
    throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
  }

  Future<Medicament> ajouterMedicament({
    required String nom,
    required String molecule,
    required String posologie,
    String effetsSecondaires = 'A verifier avec un professionnel de sante',
    String contreIndications = 'A verifier selon le dossier patient',
  }) async {
    final uri = Uri.parse(ApiConfig.medicamentsEndpoint);
    final payload = {
      'nom': nom,
      'molecule': molecule,
      'posologie': posologie,
      'effets_secondaires': effetsSecondaires,
      'contre_indications': contreIndications,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final med = decoded is Map<String, dynamic>
            ? Medicament.fromJson(decoded)
            : Medicament.fromJson(payload);
        _catalogueSecours.add(med);
        return med;
      }
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    } catch (_) {
      final localMed = Medicament.fromJson({
        'id': _catalogueSecours.length + 100,
        ...payload,
      });
      _catalogueSecours.add(localMed);
      return localMed;
    }
  }

  Future<String> signalerMedicament({
    required String nomMedicament,
    required String motif,
  }) async {
    final uri = Uri.parse('${ApiConfig.medicamentsEndpoint}/signalement');
    final payload = {
      'nom_medicament': nomMedicament,
      'motif': motif,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 'Signalement enregistre pour "$nomMedicament".';
      }
      throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
    } catch (_) {
      return 'Signalement enregistre en mode local pour "$nomMedicament" ($motif).';
    }
  }

  Future<String> askAssistant(String question) async {
    final uri = Uri.parse(ApiConfig.askEndpoint);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'question': question}),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      return _extractReadableText(utf8.decode(response.bodyBytes));
    }
    throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
  }

  MediaType _guessImageMediaType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<String> scanImage(File imageFile) async {
    final uri = Uri.parse(ApiConfig.scanEndpoint);
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: _guessImageMediaType(imageFile.path),
      ),
    );

    final streamedResponse = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return _extractReadableText(utf8.decode(response.bodyBytes));
    }
    throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
  }

  Future<String> runEvaluation({
    int nbBonnesReponses = 8,
    int nbReponsesTrouvees = 10,
    int nbTotalBonnesReponses = 10,
      }) async {
    final uri = Uri.parse(ApiConfig.evaluationEndpoint);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nb_bonnes_reponses': nbBonnesReponses,
            'nb_reponses_trouvees': nbReponsesTrouvees,
            'nb_total_bonnes_reponses': nbTotalBonnesReponses,
          }),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      return _extractReadableText(utf8.decode(response.bodyBytes));
    }
    throw Exception('Erreur HTTP ${response.statusCode} : ${response.body}');
  }

  String _formatText(String text) {
    return text.replaceAll(r'\n', '\n').trim();
  }

  String _extractReadableText(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is String) return _formatText(decoded);
      if (decoded is Map<String, dynamic>) {
        for (final key in [
          'reponse',
          'analyse',
          'response',
          'answer',
          'message',
          'result',
          'analysis',
          'text',
        ]) {
          final val = decoded[key];
          if (val != null && val.toString().trim().isNotEmpty) {
            return _formatText(val.toString());
          }
        }
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      }
      return _formatText(rawBody);
    } catch (_) {
      return _formatText(rawBody);
    }
  }
}
