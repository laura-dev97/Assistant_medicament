from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text
from app.database import Base


class Medicament(Base):
    __tablename__ = "medicaments"

    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String, index=True, nullable=False)
    molecule = Column(String, index=True, nullable=False)
    posologie = Column(Text, nullable=False)
    effets_secondaires = Column(Text, nullable=False)
    contre_indications = Column(Text, nullable=False)
    sans_ordonnance = Column(Boolean, default=True)
    valide = Column(Boolean, default=True)


class Signalement(Base):
    __tablename__ = "signalements"

    id = Column(Integer, primary_key=True, index=True)
    medicament_nom = Column(String, nullable=False)
    type_signalement = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    date_creation = Column(DateTime, default=datetime.utcnow)