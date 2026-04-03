"""Utilidades para crear servidores Modbus TCP de PLC simulados."""
"""Creado por Raúl Renales Agüero"""

from __future__ import annotations

import threading
from typing import Dict

from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
from pymodbus.server import StartTcpServer


class ObservableDataBlock(ModbusSequentialDataBlock):
    """DataBlock con mensajes simples de conexión y cambios de registros."""

    def __init__(self, plc_name: str, values: Dict[int, int]):
        # Los registros arrancan en dirección 0.
        sorted_values = [values[index] for index in sorted(values.keys())]
        super().__init__(0, sorted_values)
        self.plc_name = plc_name
        self._lock = threading.Lock()
        self._client_announced = False

    def _announce_client_if_needed(self) -> None:
        if not self._client_announced:
            print(f"[{self.plc_name}] Cliente conectado")
            self._client_announced = True

    def getValues(self, address, count=1):  # noqa: N802 (API pymodbus)
        with self._lock:
            self._announce_client_if_needed()
            return super().getValues(address, count)

    def setValues(self, address, values):  # noqa: N802 (API pymodbus)
        with self._lock:
            self._announce_client_if_needed()
            previous_values = super().getValues(address, len(values))
            super().setValues(address, values)
            for offset, new_value in enumerate(values):
                register = address + offset
                old_value = previous_values[offset]
                if old_value != new_value:
                    print(
                        f"[{self.plc_name}] Registro HR{register} cambiado: "
                        f"{old_value} → {new_value}"
                    )


def create_plc_server(plc_name: str, unit_id: int, host: str, port: int, registers: Dict[int, int]) -> None:
    """Crea e inicia un servidor Modbus TCP independiente para un PLC simulado."""

    data_block = ObservableDataBlock(plc_name=plc_name, values=registers)
    slave_context = ModbusSlaveContext(hr=data_block, zero_mode=True)
    context = ModbusServerContext(slaves={unit_id: slave_context}, single=False)

    StartTcpServer(context=context, address=(host, port))
