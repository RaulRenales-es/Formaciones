"""Mapa de memoria S7 (DB1) y utilidades de acceso bit/word."""

from __future__ import annotations

from dataclasses import dataclass, field

DB_SIZE = 64

# Estado de proceso
BOMBA_RUN = (0, 0)
BOMBA_FAULT = (0, 1)
VALVE_OPEN = (0, 2)
AGITATOR_RUN = (0, 3)
ALARM_LOW_LEVEL = (0, 4)
ALARM_HIGH_LEVEL = (0, 5)
EMERGENCY_STOP = (0, 6)

# Comandos desde cliente PLC/HMI
CMD_START_PUMP = (1, 0)
CMD_STOP_PUMP = (1, 1)
CMD_OPEN_VALVE = (1, 2)
CMD_CLOSE_VALVE = (1, 3)
CMD_RESET_ALARMS = (1, 4)

# Palabras
TANK_LEVEL = 10
AGITATOR_SPEED = 12
LEVEL_SETPOINT = 14


@dataclass
class S7MemoryMap:
    """Representación local del DB1 del simulador S7."""

    db: bytearray = field(default_factory=lambda: bytearray(DB_SIZE))

    @staticmethod
    def _get_bit(buf: bytearray, byte: int, bit: int) -> bool:
        return bool(buf[byte] & (1 << bit))

    @staticmethod
    def _set_bit(buf: bytearray, byte: int, bit: int, value: bool) -> None:
        if value:
            buf[byte] |= 1 << bit
        else:
            buf[byte] &= ~(1 << bit)

    @staticmethod
    def _get_word(buf: bytearray, byte: int) -> int:
        return (buf[byte] << 8) | buf[byte + 1]

    @staticmethod
    def _set_word(buf: bytearray, byte: int, value: int) -> None:
        clamped = max(0, min(65535, int(value)))
        buf[byte] = (clamped >> 8) & 0xFF
        buf[byte + 1] = clamped & 0xFF

    def write_state(self, state: dict) -> None:
        """Sincroniza estados internos -> DB S7."""
        self._set_bit(self.db, *BOMBA_RUN, bool(state["pump_run"]))
        self._set_bit(self.db, *BOMBA_FAULT, bool(state["pump_fault"]))
        self._set_bit(self.db, *VALVE_OPEN, bool(state["valve_open"]))
        self._set_bit(self.db, *AGITATOR_RUN, bool(state["agitator_run"]))
        self._set_bit(self.db, *ALARM_LOW_LEVEL, bool(state["alarm_low_level"]))
        self._set_bit(self.db, *ALARM_HIGH_LEVEL, bool(state["alarm_high_level"]))
        self._set_bit(self.db, *EMERGENCY_STOP, bool(state["emergency_stop"]))
        self._set_word(self.db, TANK_LEVEL, state["tank_level"])
        self._set_word(self.db, AGITATOR_SPEED, state["agitator_speed"])
        self._set_word(self.db, LEVEL_SETPOINT, state["level_setpoint"])

    def read_commands(self) -> dict:
        """Lee comandos del DB y los limpia para consumo one-shot."""
        commands = {
            "start_pump": self._get_bit(self.db, *CMD_START_PUMP),
            "stop_pump": self._get_bit(self.db, *CMD_STOP_PUMP),
            "open_valve": self._get_bit(self.db, *CMD_OPEN_VALVE),
            "close_valve": self._get_bit(self.db, *CMD_CLOSE_VALVE),
            "reset_alarms": self._get_bit(self.db, *CMD_RESET_ALARMS),
        }

        # Parámetros continuos desde DB
        commands["level_setpoint"] = self._get_word(self.db, LEVEL_SETPOINT)
        commands["agitator_speed"] = self._get_word(self.db, AGITATOR_SPEED)

        for byte, bit in [
            CMD_START_PUMP,
            CMD_STOP_PUMP,
            CMD_OPEN_VALVE,
            CMD_CLOSE_VALVE,
            CMD_RESET_ALARMS,
        ]:
            self._set_bit(self.db, byte, bit, False)

        return commands
