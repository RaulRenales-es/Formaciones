"""Modelos de PLC para el simulador fotovoltaico.

Contiene dos dataclasses simples para representar el estado de:
- PLC_Solar
- PLC_Battery

Las clases incluyen métodos auxiliares para convertir a diccionario,
actualizar valores en bloque y validar/actualizar estado de alarmas.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass


@dataclass
class PLCSolar:
    """Estado lógico del PLC Solar."""

    irradiance_wm2: float = 600.0
    panel_temp_c: float = 35.0
    string_voltage_v: float = 550.0
    string_current_a: float = 10.0
    inverter_status: str = "ON"
    alarm: bool = False

    def evaluate_alarm(self) -> None:
        """Evalúa condiciones de alarma del PLC solar.

        Criterios:
        - panel_temp_c > 70
        - string_voltage_v fuera de 300..800
        """
        self.alarm = self.panel_temp_c > 70 or not (300 <= self.string_voltage_v <= 800)
        self.inverter_status = "FAULT" if self.alarm else "ON"

    def update_from_dict(self, payload: dict) -> None:
        """Actualiza atributos permitidos desde un diccionario."""
        for field_name in (
            "irradiance_wm2",
            "panel_temp_c",
            "string_voltage_v",
            "string_current_a",
            "inverter_status",
            "alarm",
        ):
            if field_name in payload:
                setattr(self, field_name, payload[field_name])

        # Se mantiene coherencia de alarma/estado tras cambios manuales.
        self.evaluate_alarm()

    def to_dict(self) -> dict:
        """Representación serializable del estado actual."""
        return asdict(self)


@dataclass
class PLCBattery:
    """Estado lógico del PLC de baterías."""

    soc_percent: float = 65.0
    battery_voltage_v: float = 480.0
    battery_current_a: float = -10.0
    charge_mode: str = "DISCHARGE"
    temperature_c: float = 30.0
    alarm: bool = False

    def evaluate_alarm(self) -> None:
        """Evalúa condiciones de alarma del PLC de baterías.

        Criterios:
        - soc_percent < 15
        - temperature_c > 50
        """
        self.alarm = self.soc_percent < 15 or self.temperature_c > 50

    def update_from_dict(self, payload: dict) -> None:
        """Actualiza atributos permitidos desde un diccionario."""
        for field_name in (
            "soc_percent",
            "battery_voltage_v",
            "battery_current_a",
            "charge_mode",
            "temperature_c",
            "alarm",
        ):
            if field_name in payload:
                setattr(self, field_name, payload[field_name])

        # Se mantiene coherencia de alarma tras cambios manuales.
        self.evaluate_alarm()

    def to_dict(self) -> dict:
        """Representación serializable del estado actual."""
        return asdict(self)
