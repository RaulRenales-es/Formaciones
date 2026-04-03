"""Motor de simulación en memoria para PLCs fotovoltaicos."""

from __future__ import annotations

import random
import threading
import time
from typing import Any

from .plc_models import PLCBattery, PLCSolar


class SimulationEngine:
    """Gestiona estado, simulación periódica y acceso thread-safe."""

    def __init__(self, interval_seconds: float = 1.0) -> None:
        self.interval_seconds = interval_seconds
        self.solar = PLCSolar()
        self.battery = PLCBattery()
        self._lock = threading.Lock()
        self._running = False
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        """Inicia el hilo de simulación si no está en ejecución."""
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        """Detiene el hilo de simulación."""
        self._running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=2)

    def _run_loop(self) -> None:
        """Bucle continuo que actualiza ambos PLC cada intervalo."""
        while self._running:
            with self._lock:
                self._simulate_solar_step()
                self._simulate_battery_step()
            time.sleep(self.interval_seconds)

    @staticmethod
    def _clamp(value: float, min_value: float, max_value: float) -> float:
        return max(min_value, min(max_value, value))

    def _simulate_solar_step(self) -> None:
        """Aplica pequeñas variaciones realistas al PLC solar."""
        # Irradiancia con variaciones suaves.
        self.solar.irradiance_wm2 = self._clamp(
            self.solar.irradiance_wm2 + random.uniform(-70, 70),
            0,
            1000,
        )

        # Temperatura del panel relacionada parcialmente con irradiancia.
        temp_target = 15 + (self.solar.irradiance_wm2 / 1000) * 55
        self.solar.panel_temp_c = self._clamp(
            self.solar.panel_temp_c + (temp_target - self.solar.panel_temp_c) * 0.2 + random.uniform(-1.5, 1.5),
            10,
            80,
        )

        # Voltaje e intensidad del string.
        self.solar.string_voltage_v = self._clamp(
            self.solar.string_voltage_v + random.uniform(-12, 12),
            280,
            820,
        )
        expected_current = (self.solar.irradiance_wm2 / 1000) * 18
        self.solar.string_current_a = self._clamp(
            self.solar.string_current_a + (expected_current - self.solar.string_current_a) * 0.3 + random.uniform(-1.0, 1.0),
            0,
            20,
        )

        self.solar.evaluate_alarm()

    def _simulate_battery_step(self) -> None:
        """Aplica variaciones realistas al PLC de baterías."""
        # Modo de carga según irradiancia y estado de batería.
        if self.solar.irradiance_wm2 > 500 and self.battery.soc_percent < 95:
            self.battery.charge_mode = "CHARGE"
            target_current = random.uniform(20, 70)
        elif self.battery.soc_percent > 25:
            self.battery.charge_mode = "DISCHARGE"
            target_current = random.uniform(-45, -5)
        else:
            self.battery.charge_mode = "IDLE"
            target_current = random.uniform(-5, 5)

        # Corriente y SOC.
        self.battery.battery_current_a = self._clamp(
            self.battery.battery_current_a + (target_current - self.battery.battery_current_a) * 0.35 + random.uniform(-4, 4),
            -100,
            100,
        )

        soc_delta = self.battery.battery_current_a * 0.004
        self.battery.soc_percent = self._clamp(self.battery.soc_percent + soc_delta, 0, 100)

        # Voltaje correlacionado con SOC y corriente.
        base_voltage = 300 + (self.battery.soc_percent / 100) * 300
        self.battery.battery_voltage_v = self._clamp(
            base_voltage + self.battery.battery_current_a * 0.12 + random.uniform(-6, 6),
            300,
            600,
        )

        # Temperatura por carga/descarga.
        thermal_push = abs(self.battery.battery_current_a) / 100 * 2.5
        self.battery.temperature_c = self._clamp(
            self.battery.temperature_c + thermal_push + random.uniform(-1.2, 0.6) - 0.8,
            10,
            60,
        )

        self.battery.evaluate_alarm()

    def get_solar(self) -> dict[str, Any]:
        """Devuelve snapshot thread-safe del PLC solar."""
        with self._lock:
            return self.solar.to_dict()

    def get_battery(self) -> dict[str, Any]:
        """Devuelve snapshot thread-safe del PLC baterías."""
        with self._lock:
            return self.battery.to_dict()

    def set_solar(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Permite setear manualmente parámetros del PLC solar."""
        with self._lock:
            self.solar.update_from_dict(payload)
            return self.solar.to_dict()

    def set_battery(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Permite setear manualmente parámetros del PLC batería."""
        with self._lock:
            self.battery.update_from_dict(payload)
            return self.battery.to_dict()
