"""Test script to list available Gemini models."""

import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.google_api_key)

print("🔍 Listing available Gemini models...\n")

for model in genai.list_models():
    print(f"Model Name: {model.name}")
    print(f"  Display Name: {model.display_name}")
    print(f"  Description: {model.description}")
    print(f"  Supported Methods: {model.supported_generation_methods}")
    print()
