from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Dict, List, Optional

from models import PLCStatus, ParameterStatus, PlantStatus


@dataclass(frozen=True)
class RegisterRule:
    register: int
    name: str
    nominal: int
    min_value: Optional[int] = None
    max_value: Optional[int] = None
    valid_values: Optional[List[int]] = None

    def is_in_range(self, value: int) -> bool:
        if self.valid_values is not None:
            return value in self.valid_values
        if self.min_value is None or self.max_value is None:
            return True
        return self.min_value <= value <= self.max_value


PLANT_NAME = "solar_training_range"

PLC_DEFINITIONS = {
    1: {
        "name": "PLC-1",
        "host": "plc1",
        "port": 15021,
        "unit_id": 1,
        "registers": [
            RegisterRule(0, "panel_voltage_v", 690, 660, 720),
            RegisterRule(1, "panel_current_a", 120, 100, 135),
            RegisterRule(2, "inverter_temp_c", 42, 35, 55),
            RegisterRule(3, "output_power_kw", 480, 430, 520),
            RegisterRule(4, "breaker_state", 1, valid_values=[0, 1]),
            RegisterRule(5, "irradiance_wm2", 800, 700, 950),
        ],
    },
    2: {
        "name": "PLC-2",
        "host": "plc2",
        "port": 15022,
        "unit_id": 2,
        "registers": [
            RegisterRule(0, "battery_soc_pct", 78, 60, 90),
            RegisterRule(1, "battery_temp_c", 31, 20, 40),
            RegisterRule(2, "grid_export_kw", 260, 220, 300),
            RegisterRule(3, "transformer_temp_c", 46, 35, 60),
            RegisterRule(4, "cooling_state", 1, valid_values=[0, 1]),
            RegisterRule(5, "charge_cycles", 1240, 1200, 1300),
        ],
    },
}


def nominal_values(plc_id: int) -> List[int]:
    return [rule.nominal for rule in PLC_DEFINITIONS[plc_id]["registers"]]


def evaluate_plc(plc_id: int, values: List[int], read_time: Optional[datetime] = None) -> PLCStatus:
    definition = PLC_DEFINITIONS[plc_id]
    register_rules: List[RegisterRule] = definition["registers"]

    parameters: List[ParameterStatus] = []
    altered = False

    for idx, rule in enumerate(register_rules):
        value = values[idx] if idx < len(values) else 0
        in_range = rule.is_in_range(value)
        altered = altered or (not in_range)

        parameters.append(
            ParameterStatus(
                register=rule.register,
                name=rule.name,
                value=value,
                nominal=rule.nominal,
                range=[rule.min_value, rule.max_value]
                if rule.valid_values is None
                else None,
                valid_values=rule.valid_values,
                in_range=in_range,
            )
        )

    state = "ALTERED" if altered else "NOMINAL"
    lamp = "RED" if altered else "GREEN"

    return PLCStatus(
        id=plc_id,
        name=definition["name"],
        host=definition["host"],
        port=definition["port"],
        state=state,
        lamp=lamp,
        attacked=altered,
        last_read=read_time,
        parameters=parameters,
    )


def evaluate_plant(raw_values: Dict[int, List[int]], timestamps: Dict[int, datetime]) -> PlantStatus:
    plc_statuses = []
    for plc_id in sorted(PLC_DEFINITIONS.keys()):
        plc_statuses.append(
            evaluate_plc(
                plc_id=plc_id,
                values=raw_values.get(plc_id, []),
                read_time=timestamps.get(plc_id),
            )
        )

    return PlantStatus(
        plant=PLANT_NAME,
        timestamp=datetime.now(timezone.utc),
        plcs=plc_statuses,
    )
