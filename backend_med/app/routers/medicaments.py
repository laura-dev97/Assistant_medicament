from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Medicament, Signalement
from app.schemas import (
    MedicamentCreate,
    MedicamentResponse,
    SignalementCreate,
    SignalementResponse,
)

router = APIRouter(prefix="/medicaments", tags=["Medicaments"])


@router.get("/", response_model=List[MedicamentResponse])
def lister_medicaments(db: Session = Depends(get_db)):
    return db.query(Medicament).all()


@router.post("/", response_model=MedicamentResponse)
def ajouter_medicament(payload: MedicamentCreate, db: Session = Depends(get_db)):
    med = Medicament(**payload.model_dump())
    db.add(med)
    db.commit()
    db.refresh(med)
    return med


@router.post("/signalement", response_model=SignalementResponse)
def signaler_medicament(payload: SignalementCreate, db: Session = Depends(get_db)):
    sig = Signalement(**payload.model_dump())
    db.add(sig)
    db.commit()
    db.refresh(sig)
    return sig
