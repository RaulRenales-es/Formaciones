from __future__ import annotations

import threading
from typing import Dict, List

from pymodbus.datastore import (
    ModbusSequentialDataBlock,
    ModbusSlaveContext,
    ModbusServerContext,
)
from pymodbus.server import StartTcpServer


class ObservableDataBlock(ModbusSequentialDataBlock):
    """DataBlock de holding registers con trazas simples de acceso y cambios."""

    def __init__(self, plc_name: str, values: Dict[int, int]):
        if not values:
            normalized_values = [0]
        else:
            normalized_values = self._build_contiguous_register_map(values)

        super().__init__(0, normalized_values)
        self.plc_name = plc_name
        self._lock = threading.Lock()
        self._client_announced = False

    @staticmethod
    def _build_contiguous_register_map(values: Dict[int, int]) -> List[int]:
        """
        Convierte un diccionario {direccion: valor} en una lista contigua
        arrancando en 0, rellenando huecos con 0.

        Ejemplo:
            {0: 11, 1: 22, 5: 99}
        se convierte en:
            [11, 22, 0, 0, 0, 99]
        """
        min_address = min(values.keys())
        if min_address < 0:
            raise ValueError("Las direcciones de registro no pueden ser negativas.")

        max_address = max(values.keys())
        contiguous = [0] * (max_address + 1)

        for address, value in values.items():
            contiguous[address] = int(value)

        return contiguous

    def _announce_client_if_needed(self) -> None:
        if not self._client_announced:
            print(f"[{self.plc_name}] Cliente conectado")
            self._client_announced = True

    def getValues(self, address, count=1):  # noqa: N802
        with self._lock:
            self._announce_client_if_needed()
            return super().getValues(address, count)

    def setValues(self, address, values):  # noqa: N802
        with self._lock:
            self._announce_client_if_needed()

            new_values = list(values)
            previous_values = super().getValues(address, len(new_values))
            super().setValues(address, new_values)

            for offset, new_value in enumerate(new_values):
                register = address + offset
                old_value = previous_values[offset]
                if old_value != new_value:
                    print(
                        f"[{self.plc_name}] Registro HR{register} cambiado: "
                        f"{old_value} → {new_value}"
                    )


def create_plc_server(
    plc_name: str,
    unit_id: int,
    host: str,
    port: int,
    registers: Dict[int, int],
) -> None:
    """Crea e inicia un servidor Modbus TCP para un PLC simulado."""

    if not (0 <= unit_id <= 247):
        raise ValueError("unit_id debe estar entre 0 y 247.")

    data_block = ObservableDataBlock(plc_name=plc_name, values=registers)

    slave_context = ModbusSlaveContext(
        hr=data_block,
        di=ModbusSequentialDataBlock(0, [0]),
        co=ModbusSequentialDataBlock(0, [0]),
        ir=ModbusSequentialDataBlock(0, [0]),
    )

    context = ModbusServerContext(
        slaves={unit_id: slave_context},
        single=False,
    )

    print(f"[{plc_name}] Servidor Modbus TCP escuchando en {host}:{port} (unit_id={unit_id})")
    StartTcpServer(
        context=context,
        address=(host, port),
    )
