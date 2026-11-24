from app.database import Base, SessionLocal, engine
from app.models import Medicament

Base.metadata.create_all(bind=engine)
db = SessionLocal()

exemples = [
    Medicament(
        nom="Paracetamol 500mg",
        molecule="Paracetamol",
        posologie="1 comprime de 500mg toutes les 6 heures, maximum 3g par jour chez l'adulte.",
        effets_secondaires="Rares reactions cutanees ou atteinte hepatique en cas de surdosage.",
        contre_indications="Insuffisance hepatique severe, allergie au paracetamol.",
        sans_ordonnance=True,
        valide=True,
    ),
    Medicament(
        nom="Ibuprofene 200mg",
        molecule="Ibuprofene",
        posologie="1 comprime de 200mg a 400mg si besoin, espacer les prises d'au moins 6 heures.",
        effets_secondaires="Troubles digestifs, maux d'estomac, nausees.",
        contre_indications="Ulcere gastrique, grossesse (a partir du 6e mois), insuffisance renale.",
        sans_ordonnance=True,
        valide=True,
    ),
]

if db.query(Medicament).count() == 0:
    db.add_all(exemples)
    db.commit()
    print("Medicaments de test ajoutes dans medecine.db.")
else:
    print("La base contient deja des medicaments.")

db.close()