#!/usr/bin/env bash
set -e
python -m pip install -U pip pytest
pytest -q
