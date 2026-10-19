#!/usr/bin/env python3
"""Run from backend with the configured environment. Does not connect to the DB."""
import json
from pathlib import Path
from app.main import app
path=Path(__file__).resolve().parents[1]/'docs/api/openapi.json'
path.parent.mkdir(parents=True,exist_ok=True)
path.write_text(json.dumps(app.openapi(),indent=2)+'\n')
print(path)
