from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Medicament
from app.schemas import AssistantResponse, QuestionRequest
from app.services.gemini_service import (
    analyser_image_medicament,
    repondre_avec_catalogue,
)

router = APIRouter(prefix="/assistant", tags=["Assistant IA"])


@router.post("/ask", response_model=AssistantResponse)
def poser_question(payload: QuestionRequest, db: Session = Depends(get_db)):
    medicaments = db.query(Medicament).all()

    if medicaments:
        lignes = [
            f"- {m.nom} ({m.molecule}) | Posologie: {m.posologie} | "
            f"Effets secondaires: {m.effets_secondaires} | Contre-indications: {m.contre_indications}"
            for m in medicaments
        ]
        contexte = "\n".join(lignes)
        noms = [m.nom for m in medicaments]
    else:
        contexte = "Aucun medicament enregistre pour le moment."
        noms = []

    try:
        reponse = repondre_avec_catalogue(payload.question, contexte)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Erreur Gemini: {e}")

    return AssistantResponse(reponse=reponse, medicaments_utilises=noms)


@router.post("/scan")
async def scanner_medicament(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Veuillez envoyer une image valide.")

    image_bytes = await file.read()
    try:
        analyse = analyser_image_medicament(image_bytes)
    except ValueError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Erreur Gemini: {e}")

    return {"analyse": analyse}
