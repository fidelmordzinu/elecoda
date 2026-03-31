from google import genai
from google.genai import types
import os
import json
import re
import logging
from dotenv import load_dotenv

logger = logging.getLogger(__name__)

load_dotenv()

_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

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


async def generate_circuit(query: str, inventory: list[str]) -> dict:
    try:
        inventory_str = ", ".join(inventory) if inventory else "None"
        prompt = SYSTEM_PROMPT.format(query=query, inventory=inventory_str)

        response = await _client.aio.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema={
                    "type": "OBJECT",
                    "properties": {
                        "components": {
                            "type": "ARRAY",
                            "items": {
                                "type": "OBJECT",
                                "properties": {
                                    "ref": {"type": "STRING"},
                                    "type": {"type": "STRING"},
                                    "value": {"type": "STRING"},
                                    "mpn": {"type": "STRING"},
                                    "in_inventory": {"type": "BOOLEAN"},
                                },
                                "required": ["ref", "type", "value"],
                            },
                        },
                        "connections": {
                            "type": "ARRAY",
                            "items": {
                                "type": "OBJECT",
                                "properties": {
                                    "from": {"type": "STRING"},
                                    "to": {"type": "STRING"},
                                },
                                "required": ["from", "to"],
                            },
                        },
                    },
                    "required": ["components", "connections"],
                },
            ),
        )

        text = response.text.strip()

        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            text = match.group(0)

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
