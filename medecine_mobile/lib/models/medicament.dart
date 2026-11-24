class Medicament {
  final int id;
  final String nom;
  final String molecule;
  final String posologie;
  final String effetsSecondaires;
  final String contreIndications;
  final bool sansOrdonnance;
  final bool valide;

  Medicament({
    required this.id,
    required this.nom,
    required this.molecule,
    required this.posologie,
    required this.effetsSecondaires,
    required this.contreIndications,
    required this.sansOrdonnance,
    required this.valide,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? 0}') ?? 0,
      nom: (json['nom'] ?? '').toString(),
      molecule: (json['molecule'] ?? '').toString(),
      posologie: (json['posologie'] ?? '').toString(),
      effetsSecondaires: (json['effets_secondaires'] ?? '').toString(),
      contreIndications: (json['contre_indications'] ?? '').toString(),
      sansOrdonnance: json['sans_ordonnance'] == true,
      valide: json['valide'] == null ? true : json['valide'] == true,
    );
  }
}
