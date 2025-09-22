#!/usr/bin/env bash
set -Eeuo pipefail

python3 -m venv .venv
source .venv/bin/activate

pip install -U pip
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
elif [ -f app/requirements.txt ]; then
  pip install -r app/requirements.txt
fi

export PYTHONPATH="$(pwd):${PYTHONPATH:-}"
python -m unittest -v unit_test.py
