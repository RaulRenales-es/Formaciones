"""Mapas y constantes de registros para PLCs simulados."""

# PLC-1 (unit_id=1)
PLC1_UNIT_ID = 1
PLC1_REGISTERS = {
    0: 690,   # panel_voltage_v
    1: 120,   # panel_current_a
    2: 42,    # inverter_temp_c
    3: 480,   # output_power_kw
    4: 1,     # breaker_state
    5: 800,   # irradiance_wm2
}

# PLC-2 (unit_id=2)
PLC2_UNIT_ID = 2
PLC2_REGISTERS = {
    0: 78,    # battery_soc_pct
    1: 31,    # battery_temp_c
    2: 260,   # grid_export_kw
    3: 46,    # transformer_temp_c
    4: 1,     # cooling_state
    5: 1240,  # charge_cycles
}

# Valores nominales agrupados para facilitar reutilización/consulta
NOMINAL_VALUES = {
    "PLC-1": PLC1_REGISTERS,
    "PLC-2": PLC2_REGISTERS,
}
