# Solar OT Training Range (Simulado)

> **Uso exclusivo en entornos aislados de laboratorio y formación autorizada.**

Plataforma didáctica OT/ICS para entrenamiento controlado de manipulación de registros Modbus TCP sobre **2 PLCs simulados** de una planta solar. El alumno puede leer/escribir registros de los PLCs y observar en la HMI web cómo cambia el estado de cada controlador de **NOMINAL** a **ALTERED**.

## 1) Descripción del laboratorio

- **PLC-1**: generación/inversor del campo A.
- **PLC-2**: almacenamiento/batería y distribución del campo B.
- **Backend FastAPI**: sondea ambos PLCs cada 1 segundo, evalúa rangos nominales y expone API + WebSocket.
- **Frontend React (Vite)**: HMI de página única con diagrama de planta, tablas de parámetros y luces de estado.

No hay lógica de proceso físico compleja; el objetivo es didáctico: manipulación de registros y detección visual inmediata.

## 2) Arquitectura

Servicios Docker Compose:

1. `plc1` (PyModbus server TCP, unit id 1, puerto 15021)
2. `plc2` (PyModbus server TCP, unit id 2, puerto 15022)
3. `backend` (FastAPI + PyModbus client, puerto 8000)
4. `frontend` (React + Vite, puerto 5173)

Todos los servicios viven en la red bridge dedicada `otlab_net`.

## 3) Puertos

- HMI web: `5173`
- API backend: `8000`
- Modbus TCP PLC-1: `15021`
- Modbus TCP PLC-2: `15022`

## 4) Arranque

Desde `project-root`:

```bash
docker compose up --build
```

Accesos:

- HMI: http://localhost:5173
- API status: http://localhost:8000/api/plants/status

## 5) Mapa de registros Modbus (Holding Registers, base 0)

### PLC-1 (unit/slave id 1, puerto 15021)

- HR0  `panel_voltage_v` nominal 690, rango `[660, 720]`
- HR1  `panel_current_a` nominal 120, rango `[100, 135]`
- HR2  `inverter_temp_c` nominal 42, rango `[35, 55]`
- HR3  `output_power_kw` nominal 480, rango `[430, 520]`
- HR4  `breaker_state` nominal 1, valores `{0,1}`
- HR5  `irradiance_wm2` nominal 800, rango `[700, 950]`

### PLC-2 (unit/slave id 2, puerto 15022)

- HR0  `battery_soc_pct` nominal 78, rango `[60, 90]`
- HR1  `battery_temp_c` nominal 31, rango `[20, 40]`
- HR2  `grid_export_kw` nominal 260, rango `[220, 300]`
- HR3  `transformer_temp_c` nominal 46, rango `[35, 60]`
- HR4  `cooling_state` nominal 1, valores `{0,1}`
- HR5  `charge_cycles` nominal 1240, rango `[1200, 1300]`

## 6) Endpoints

- `GET /api/plants/status`
- `GET /api/plants/plc/1`
- `GET /api/plants/plc/2`
- `POST /api/reset/plc/1`
- `POST /api/reset/plc/2`
- `WS /ws/status`

Regla de detección:

- `NOMINAL`: todos los parámetros dentro de rango/valor esperado.
- `ALTERED`: al menos un parámetro fuera de rango.

## 7) Pruebas reproducibles / demo

### Opción A: cliente tipo `modbus-cli` (si lo tienes instalado)

Leer 6 HR de PLC-1:

```bash
modbus read 127.0.0.1:15021 -u 1 -t holding -a 0 -q 6
```

Escribir valor fuera de rango en HR2 de PLC-1 (temperatura inversor):

```bash
modbus write 127.0.0.1:15021 -u 1 -t holding -a 2 99
```

Luego revisa la HMI; PLC-1 debe pasar a rojo (`ATTACK / MANIPULATED`).

### Opción B: script Python de ejemplo (sin modbus-cli)

Ejecuta desde tu host con Python y pymodbus instalados:

```python
from pymodbus.client import ModbusTcpClient

# Leer PLC-1
c = ModbusTcpClient('127.0.0.1', port=15021)
c.connect()
print(c.read_holding_registers(0, 6, slave=1).registers)

# Alterar HR2 fuera de rango
c.write_register(address=2, value=99, slave=1)
print(c.read_holding_registers(0, 6, slave=1).registers)
c.close()
```

## 8) Reset de PLCs

- Reset PLC-1:

```bash
curl -X POST http://localhost:8000/api/reset/plc/1
```

- Reset PLC-2:

```bash
curl -X POST http://localhost:8000/api/reset/plc/2
```

Al resetear, el backend restaura valores nominales vía Modbus y la HMI vuelve a estado verde.

## 9) Seguridad y alcance

- Proyecto diseñado **solo** para laboratorio local aislado.
- No incluye escaneo externo ni explotación de terceros.
- No desplegar en Internet.
- Mantener acceso únicamente para formación autorizada.
