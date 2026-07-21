"""
Vercel serverless entry point for JagoFarm API.
"""
import sys, os

# Ensure backend/ is in Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from backend.main import app
