def calculer_metriques(
    nb_bonnes_reponses: int,
    nb_reponses_trouvees: int,
    nb_total_bonnes_reponses: int,
) -> dict:
    precision = (
        (nb_bonnes_reponses / nb_reponses_trouvees) * 100
        if nb_reponses_trouvees > 0
        else 0.0
    )
    rappel = (
        (nb_bonnes_reponses / nb_total_bonnes_reponses) * 100
        if nb_total_bonnes_reponses > 0
        else 0.0
    )

    if (precision + rappel) > 0:
        f1_score = 2 * (precision * rappel) / (precision + rappel)
    else:
        f1_score = 0.0

    return {
        "precision": round(precision, 2),
        "rappel": round(rappel, 2),
        "f1_score": round(f1_score, 2),
    }
