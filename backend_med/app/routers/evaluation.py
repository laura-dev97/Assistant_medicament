from fastapi import APIRouter
from app.schemas import EvaluationRequest, EvaluationResponse
from app.services.metrics import calculer_metriques

router = APIRouter(prefix="/evaluation", tags=["Evaluation"])


@router.post("/run", response_model=EvaluationResponse)
def evaluer(payload: EvaluationRequest):
    resultats = calculer_metriques(
        nb_bonnes_reponses=payload.nb_bonnes_reponses,
        nb_reponses_trouvees=payload.nb_reponses_trouvees,
        nb_total_bonnes_reponses=payload.nb_total_bonnes_reponses,
    )
    return EvaluationResponse(**resultats)
