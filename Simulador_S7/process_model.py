"""Lógica de proceso del simulador."""

from __future__ import annotations

from dataclasses import asdict, dataclass


@dataclass
class ProcessState:
    pump_run: bool = False
    pump_fault: bool = False
    pump_enable: bool = True
    valve_open: bool = False
    agitator_run: bool = False
    agitator_speed: int = 0
    speed_setpoint: int = 30
    tank_level: int = 50
    level_setpoint: int = 60
    alarm_low_level: bool = False
    alarm_high_level: bool = False
    emergency_stop: bool = False


class ProcessModel:
    """Modelo simple de tanque con bomba, válvula y agitador."""

    def __init__(self) -> None:
        self.state = ProcessState()

    def apply_commands(self, commands: dict) -> None:
        s = self.state

        if "level_setpoint" in commands:
            s.level_setpoint = max(0, min(100, int(commands["level_setpoint"])))

        if "agitator_speed" in commands:
            s.speed_setpoint = max(0, min(100, int(commands["agitator_speed"])))

        if commands.get("reset_alarms"):
            s.alarm_low_level = False
            s.alarm_high_level = False
            s.pump_fault = False
            s.emergency_stop = False

        if commands.get("open_valve") and not s.emergency_stop:
            s.valve_open = True
        if commands.get("close_valve"):
            s.valve_open = False

        if commands.get("start_pump") and s.pump_enable and not s.pump_fault and not s.emergency_stop:
            s.pump_run = True
            s.agitator_run = True

        if commands.get("stop_pump"):
            s.pump_run = False
            s.agitator_run = False

    def step(self) -> None:
        s = self.state

        if s.emergency_stop:
            s.pump_run = False
            s.valve_open = False
            s.agitator_run = False

        level_delta = 0
        if s.valve_open:
            level_delta += 2
        if s.pump_run:
            level_delta -= 3

        s.tank_level = max(0, min(100, s.tank_level + level_delta))

        if s.tank_level <= 10:
            s.alarm_low_level = True
        if s.tank_level >= 90:
            s.alarm_high_level = True

        if s.alarm_low_level or s.alarm_high_level:
            s.pump_fault = True
            s.pump_run = False

        if s.agitator_run:
            target = s.speed_setpoint
            if s.agitator_speed < target:
                s.agitator_speed = min(target, s.agitator_speed + 5)
            elif s.agitator_speed > target:
                s.agitator_speed = max(target, s.agitator_speed - 5)
        else:
            s.agitator_speed = max(0, s.agitator_speed - 8)

    def snapshot(self) -> dict:
        state = asdict(self.state)
        state["agitator_speed"] = int(self.state.agitator_speed)
        state["tank_level"] = int(self.state.tank_level)
        return state
