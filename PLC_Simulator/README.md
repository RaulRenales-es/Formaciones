# PLC Simulator by Raúl Renales

Simulador didáctico local de **dos PLC industriales** usando **Modbus TCP** con Python 3.

Al ejecutar el script principal se levantan dos servidores Modbus TCP independientes, cada uno con su propio `unit_id`, puerto y mapa de registros holding en memoria.

## Requisitos

- Python 3.10+

## Instalación

```bash
pip install -r requirements.txt
```

## Ejecución

```bash
python plc_simulator.py
```

Al iniciar se mostrarán mensajes como:

- `[INFO] PLC-1 iniciado en puerto 15021`
- `[INFO] PLC-2 iniciado en puerto 15022`

## Mapa de registros

Los registros inician en dirección **0**.

### PLC-1 (`unit_id = 1`, puerto `15021`)

- HR0 → `panel_voltage_v` = 690
- HR1 → `panel_current_a` = 120
- HR2 → `inverter_temp_c` = 42
- HR3 → `output_power_kw` = 480
- HR4 → `breaker_state` = 1
- HR5 → `irradiance_wm2` = 800

### PLC-2 (`unit_id = 2`, puerto `15022`)

- HR0 → `battery_soc_pct` = 78
- HR1 → `battery_temp_c` = 31
- HR2 → `grid_export_kw` = 260
- HR3 → `transformer_temp_c` = 46
- HR4 → `cooling_state` = 1
- HR5 → `charge_cycles` = 1240

## Ejemplos de prueba

Lectura:

```bash
modbus-cli read holding \
  --host localhost \
  --port 15021 \
  --unit 1 \
  --address 0 \
  --quantity 6
```

Escritura:

```bash
modbus-cli write holding \
  --host localhost \
  --port 15021 \
  --unit 1 \
  --address 0 \
  --value 900
```

## Notas

- Escritura libre de registros para prácticas de laboratorio.
- Los cambios permanecen en memoria mientras el proceso esté activo.
- Sin GUI, web, base de datos ni protocolos adicionales.
