# Simulador S7 by Raúl Renales Agüero

Simulador de proceso industrial con:
- Servidor Siemens S7 (DB1) usando `python-snap7`.
- Backend web con FastAPI.
- HMI web en tiempo real con WebSocket.
- Sincronización bidireccional entre memoria S7 y estado interno.

## Estructura

- `process_model.py`: lógica del proceso (bomba, válvula, agitador, tanque y alarmas).
- `memory_map.py`: mapa de memoria DB1 y acceso a bits/palabras.
- `s7_server.py`: servidor S7 simulado.
- `api.py`: API HTTP + WebSocket + publicación HMI.
- `main.py`: arranque único de todo el sistema.
- `web/`: interfaz HMI industrial.
- `tests/`: pruebas básicas del modelo.

## Mapa de memoria (DB1)

- DB1.DBX0.0 `bomba_run`
- DB1.DBX0.1 `bomba_fault`
- DB1.DBX0.2 `valve_open`
- DB1.DBX0.3 `agitator_run`
- DB1.DBX0.4 `alarm_low_level`
- DB1.DBX0.5 `alarm_high_level`
- DB1.DBX0.6 `emergency_stop`
- DB1.DBX1.0 `cmd_start_pump`
- DB1.DBX1.1 `cmd_stop_pump`
- DB1.DBX1.2 `cmd_open_valve`
- DB1.DBX1.3 `cmd_close_valve`
- DB1.DBX1.4 `cmd_reset_alarms`
- DB1.DBW10 `tank_level`
- DB1.DBW12 `agitator_speed`
- DB1.DBW14 `level_setpoint`

## Requisitos

- Python 3.10+

## Instalación

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Arranque (un único comando)

```bash
python main.py
```

Servicios:
- HMI web: `http://localhost:8000`
- Servidor S7: `0.0.0.0:10200` (DB1)

## Tests

```bash
pytest -q
```
