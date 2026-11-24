from typing import List, Optional
from pydantic import BaseModel


class MedicamentCreate(BaseModel):
    nom: str
    molecule: str
    posologie: str
    effets_secondaires: str
    contre_indications: str
    sans_ordonnance: bool = True


class MedicamentResponse(MedicamentCreate):
    id: int
    valide: bool

    class Config:
        from_attributes = True


class SignalementCreate(BaseModel):
    medicament_nom: str
    type_signalement: str
    description: str


class SignalementResponse(SignalementCreate):
    id: int

    class Config:
        from_attributes = True


class QuestionRequest(BaseModel):
    question: str


class AssistantResponse(BaseModel):
    reponse: str
    medicaments_utilises: List[str]


class EvaluationRequest(BaseModel):
    nb_bonnes_reponses: int
    nb_reponses_trouvees: int
    nb_total_bonnes_reponses: int


class EvaluationResponse(BaseModel):
    precision: float
    rappel: float
    f1_score: float