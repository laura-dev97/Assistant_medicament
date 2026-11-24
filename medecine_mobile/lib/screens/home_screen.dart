import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/acteur_role.dart';
import '../models/medicament.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  ActeurRole _role = ActeurRole.usager;
  int _selectedIndex = 0;

  // --- État Catalogue ---
  List<Medicament> _medicaments = [];
  bool _loadingCatalogue = false;
  bool _modeSecoursActif = false;
  String? _erreurCatalogue;

  // --- État Assistant ---
  final TextEditingController _questionController = TextEditingController();
  String? _reponseAssistant;
  bool _loadingAssistant = false;
  String? _erreurAssistant;

  // --- État Scan ---
  File? _imageSelectionnee;
  String? _resultatScan;
  bool _loadingScan = false;
  String? _erreurScan;

  // --- État Évaluation ---
  String? _resultatEvaluation;
  bool _loadingEvaluation = false;
  String? _erreurEvaluation;

  @override
  void initState() {
    super.initState();
    _chargerCatalogue();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _onRoleChanged(ActeurRole nouveauRole) {
    setState(() {
      _role = nouveauRole;
      if (_role == ActeurRole.usager && _selectedIndex == 3) {
        _selectedIndex = 0;
      }
    });
  }

  Future<void> _chargerCatalogue() async {
    setState(() {
      _loadingCatalogue = true;
      _erreurCatalogue = null;
    });
    try {
      final items = await _apiService.getMedicaments();
      if (!mounted) return;
      setState(() {
        _medicaments = items;
        _modeSecoursActif = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _medicaments = _apiService.catalogueLocal;
        _modeSecoursActif = true;
        _erreurCatalogue = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingCatalogue = false;
        });
      }
    }
  }

  Future<void> _ouvrirDialogueAjoutMedicament() async {
    final nomCtrl = TextEditingController();
    final moleculeCtrl = TextEditingController();
    final posologieCtrl = TextEditingController();
    final contreIndicationsCtrl = TextEditingController(
      text: 'Aucune contre-indication specifiee',
    );

    final valide = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle fiche médicament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom (ex: Amoxicilline 500mg)'),
              ),
              TextField(
                controller: moleculeCtrl,
                decoration: const InputDecoration(labelText: 'Molécule'),
              ),
              TextField(
                controller: posologieCtrl,
                decoration: const InputDecoration(labelText: 'Posologie'),
              ),
              TextField(
                controller: contreIndicationsCtrl,
                decoration: const InputDecoration(labelText: 'Contre-indications'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (valide != true) return;

    final nom = nomCtrl.text.trim();
    final molecule = moleculeCtrl.text.trim();
    final posologie = posologieCtrl.text.trim();
    final contreIndications = contreIndicationsCtrl.text.trim();

    if (nom.isEmpty || molecule.isEmpty || posologie.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir le nom, la molécule et la posologie.')),
      );
      return;
    }

    try {
      await _apiService.ajouterMedicament(
        nom: nom,
        molecule: molecule,
        posologie: posologie,
        contreIndications:
            contreIndications.isEmpty ? 'A verifier selon le dossier patient' : contreIndications,
      );
      await _chargerCatalogue();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fiche "$nom" ajoutée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout : $e')),
      );
    }
  }

  Future<void> _ouvrirDialogueSignalement(Medicament med) async {
    final motifCtrl = TextEditingController(text: 'Produit suspect ou notice incomplète');

    final envoyer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Signaler ${med.nom}'),
        content: TextField(
          controller: motifCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Motif du signalement',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (envoyer != true) return;
    final motif = motifCtrl.text.trim().isEmpty ? 'Signalement usager' : motifCtrl.text.trim();

    final msg = await _apiService.signalerMedicament(
      nomMedicament: med.nom,
      motif: motif,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _envoyerQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _loadingAssistant = true;
      _erreurAssistant = null;
    });
    try {
      final rep = await _apiService.askAssistant(question);
      if (!mounted) return;
      setState(() {
        _reponseAssistant = rep;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurAssistant = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAssistant = false;
        });
      }
    }
  }

  Future<void> _choisirEtScannerImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _imageSelectionnee = file;
        _resultatScan = null;
        _erreurScan = null;
        _loadingScan = true;
      });

      final analyse = await _apiService.scanImage(file);
      if (!mounted) return;
      setState(() {
        _resultatScan = analyse;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurScan = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingScan = false;
        });
      }
    }
  }

  Future<void> _lancerEvaluation() async {
    setState(() {
      _loadingEvaluation = true;
      _erreurEvaluation = null;
    });
    try {
      final res = await _apiService.runEvaluation();
      if (!mounted) return;
      setState(() {
        _resultatEvaluation = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurEvaluation = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingEvaluation = false;
        });
      }
    }
  }

  List<NavigationDestination> _destinations() {
    final base = const [
      NavigationDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication),
        label: 'Catalogue',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Assistant',
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_alt_outlined),
        selectedIcon: Icon(Icons.camera_alt),
        label: 'Scan',
      ),
    ];

    if (_role == ActeurRole.usager) {
      return base;
    }

    return [
      ...base,
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'Évaluation',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();
    final safeIndex = _selectedIndex < destinations.length ? _selectedIndex : 0;
    final peutAjouter = _role != ActeurRole.usager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Médical'),
      ),
      floatingActionButton: (safeIndex == 0 && peutAjouter)
          ? FloatingActionButton.extended(
              onPressed: _ouvrirDialogueAjoutMedicament,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter fiche'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<ActeurRole>(
              segments: ActeurRole.values
                  .map(
                    (r) => ButtonSegment<ActeurRole>(
                      value: r,
                      label: Text(
                        r == ActeurRole.proSante ? 'Pro. santé' : r.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              selected: <ActeurRole>{_role},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  _onRoleChanged(selection.first);
                }
              },
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _role.responsabilite,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (_modeSecoursActif && safeIndex == 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Serveur distant injoignable : affichage des données locales de secours.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: _buildTabContent(safeIndex),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: destinations,
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildCatalogueTab();
      case 1:
        return _buildAssistantTab();
      case 2:
        return _buildScanTab();
      case 3:
      default:
        return _buildEvaluationTab();
    }
  }

  Widget _buildCatalogueTab() {
    if (_loadingCatalogue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_medicaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Aucun médicament disponible.'),
              if (_erreurCatalogue != null) ...[
                const SizedBox(height: 8),
                Text(_erreurCatalogue!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _chargerCatalogue,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _chargerCatalogue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
        itemCount: _medicaments.length,
        itemBuilder: (context, index) {
          final med = _medicaments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          med.nom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (_role == ActeurRole.usager)
                        TextButton.icon(
                          onPressed: () => _ouvrirDialogueSignalement(med),
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Signaler'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Molécule : ${med.molecule}'),
                  Text('Posologie : ${med.posologie}'),
                  Text('Contre-indications : ${med.contreIndications}'),
                  if (_role != ActeurRole.usager)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _role == ActeurRole.proSante
                            ? 'Vue Professionnel de santé : fiche vérifiable / évaluable'
                            : 'Vue Administrateur : supervision du catalogue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssistantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _questionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Posez votre question sur un médicament...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _loadingAssistant ? null : _envoyerQuestion,
            icon: const Icon(Icons.send),
            label: Text(_loadingAssistant ? 'Envoi...' : 'Envoyer la question'),
          ),
          const SizedBox(height: 14),
          if (_erreurAssistant != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _erreurAssistant!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          if (_reponseAssistant != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réponse de l\'assistant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_reponseAssistant!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadingScan
                      ? null
                      : () => _choisirEtScannerImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Caméra'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadingScan
                      ? null
                      : () => _choisirEtScannerImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_imageSelectionnee != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _imageSelectionnee!,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          if (_loadingScan) const Center(child: CircularProgressIndicator()),
          if (_erreurScan != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _erreurScan!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          if (_resultatScan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(_resultatScan!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvaluationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _loadingEvaluation ? null : _lancerEvaluation,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              _loadingEvaluation ? 'Évaluation en cours...' : 'Lancer l\'évaluation',
            ),
          ),
          const SizedBox(height: 14),
          if (_erreurEvaluation != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _erreurEvaluation!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          if (_resultatEvaluation != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(_resultatEvaluation!),
              ),
            ),
        ],
      ),
    );
  }
}