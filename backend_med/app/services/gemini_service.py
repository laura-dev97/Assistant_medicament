import io
from google import genai
from google.genai import types
from PIL import Image
from app.config import settings


def _get_client() -> genai.Client:
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY est manquante dans le fichier .env")
    return genai.Client(api_key=settings.GEMINI_API_KEY)


def repondre_avec_catalogue(question: str, contexte_catalogue: str) -> str:
    client = _get_client()

    system_instruction = (
        "Tu es un assistant d'information sur les medicaments en vente libre.\n"
        "Regles simples :\n"
        "1. Appuie-toi en priorite sur le catalogue fourni ci-dessous.\n"
        "2. Donne des informations claires sur la posologie, les effets secondaires et les contre-indications.\n"
        "3. Si l'information manque ou necessite un avis medical, conseille de consulter un professionnel de sante.\n\n"
        f"CATALOGUE :\n{contexte_catalogue}"
    )

    response = client.models.generate_content(
        model="gemini-3.5-flash-lite",
        contents=question,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.2,
        ),
    )
    return response.text or "Aucune reponse generee."


def analyser_image_medicament(image_bytes: bytes) -> str:
    client = _get_client()
    image = Image.open(io.BytesIO(image_bytes))

    prompt = (
        "Analyse cette image de medicament :\n"
        "- Identifie le nom ou la molecule visible si possible.\n"
        "- Indique les informations lisibles (dosage, usage courant).\n"
        "- Rappelle de verifier la notice et de demander conseil a un pharmacien ou medecin."
    )

    response = client.models.generate_content(
        model="gemini-3.5-flash-lite",
        contents=[image, prompt],
    )
    return response.text or "Impossible d'analyser l'image."
