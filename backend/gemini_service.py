import google.generativeai as genai
import os
import json
import logging

logger = logging.getLogger(__name__)

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

SYSTEM_PROMPT = """You are an electronics expert. The user wants to build: {query}.
The user already owns these components (MPNs/descriptions): {inventory}.
Suggest the list of all components needed for the circuit, marking which ones are already in inventory.
Output ONLY a JSON object with:
{{
  "components": [
    {{"ref": "R1", "type": "resistor", "value": "10k", "mpn": "optional", "in_inventory": false}}
  ],
  "connections": [
    {{"from": "R1.pin1", "to": "Q1.base"}}
  ]
}}"""


def generate_circuit(query: str, inventory: list[str]) -> dict:
    try:
        inventory_str = ", ".join(inventory) if inventory else "None"
        prompt = SYSTEM_PROMPT.format(query=query, inventory=inventory_str)

        model = genai.GenerativeModel("gemini-1.5-flash")
        response = model.generate_content(prompt)

        text = response.text.strip()

        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        result = json.loads(text)

        if "components" not in result:
            result["components"] = []
        if "connections" not in result:
            result["connections"] = []

        return result
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Gemini response as JSON: {e}")
        raise ValueError("Invalid response from AI service")
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        raise
