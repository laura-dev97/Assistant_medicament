enum ActeurRole {
  usager('Usager', 'Scan & Chatbot'),
  proSante('Professionnel de santé', 'Fiches & Évaluation IA'),
  administrateur('Administrateur', 'Supervision & Évaluation');

  final String label;
  final String resume;
  const ActeurRole(this.label, this.resume);

  String get responsabilite {
    switch (this) {
      case ActeurRole.usager:
        return 'Usager : scanner un médicament, interroger le chatbot médical et signaler un produit suspect/périmé (usage informatif).';
      case ActeurRole.proSante:
        return 'Professionnel de santé : gérer/valider les fiches médicaments et participer à l’évaluation de l’IA (benchmark).';
      case ActeurRole.administrateur:
        return 'Administrateur : superviser le système (comptes pros, offres Free/Silver/Gold, état API) et lancer l’évaluation.';
    }
  }
}
