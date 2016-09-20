#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

PYTHONPATH=.:google-maps-services-python:requests exec python3 process_regions.py
