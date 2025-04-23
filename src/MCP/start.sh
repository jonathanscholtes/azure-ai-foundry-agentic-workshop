#!/bin/bash
python math_server.py &
python finance_server.py &
python nlp_server.py &
uvicorn proxy_server:app --host 0.0.0.0 --port 8000