# PV_PLC_Simulator

Simulador didáctico de una instalación fotovoltaica con dos PLCs lógicos en memoria y una HMI web.

## Características

- **PLC_Solar** con variables:
  - `irradiance_wm2`
  - `panel_temp_c`
  - `string_voltage_v`
  - `string_current_a`
  - `inverter_status`
  - `alarm`
- **PLC_Battery** con variables:
  - `soc_percent`
  - `battery_voltage_v`
  - `battery_current_a`
  - `charge_mode`
  - `temperature_c`
  - `alarm`
- Actualización automática cada **1 segundo**.
- API REST para lectura y escritura de valores.
- HMI web con estado visual:
  - **verde** = normal
  - **rojo** = alarma
- Sin base de datos, todo el estado se mantiene en memoria.

## Estructura

```text
PV_PLC_Simulator/
  main.py
  simulator/
    __init__.py
    plc_models.py
    engine.py
  templates/
    index.html
  static/
    style.css
    app.js
  requirements.txt
  README.md
```

## Requisitos

- Python **3.10+**

## Instalación

```bash
cd PV_PLC_Simulator
python -m venv .venv
source .venv/bin/activate   # En Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
```

## Ejecución

```bash
uvicorn main:app --reload
```

Abrir en navegador:

- <http://127.0.0.1:8000>

## Endpoints API

### Lectura

- `GET /api/plc/solar`
- `GET /api/plc/battery`

### Escritura

- `POST /api/plc/solar/set`
- `POST /api/plc/battery/set`

Ejemplo de escritura para Solar:

```bash
curl -X POST "http://127.0.0.1:8000/api/plc/solar/set" \
  -H "Content-Type: application/json" \
  -d '{"panel_temp_c": 75, "string_voltage_v": 820}'
```

Ejemplo de escritura para Battery:

```bash
curl -X POST "http://127.0.0.1:8000/api/plc/battery/set" \
  -H "Content-Type: application/json" \
  -d '{"soc_percent": 10, "temperature_c": 52}'
```

## Lógica de alarmas

- **Solar**: `alarm = true` si:
  - `panel_temp_c > 70`
  - `string_voltage_v` fuera de `[300, 800]`
- **Battery**: `alarm = true` si:
  - `soc_percent < 15`
  - `temperature_c > 50`

## Notas

- Diseñado para demostración y pruebas de concepto.
- El motor de simulación usa un hilo en background con bloqueo (`threading.Lock`) para asegurar lecturas/escrituras coherentes.
