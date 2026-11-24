from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from app.routers import assistant, evaluation, medicaments

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Backend Assistant Medicaments IA")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(medicaments.router)
app.include_router(assistant.router)
app.include_router(evaluation.router)


@app.get("/")
def accueil():
    return {"message": "API OK"}

