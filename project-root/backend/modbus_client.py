from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Dict, List, Tuple

from pymodbus.client import ModbusTcpClient

from state_engine import PLC_DEFINITIONS, nominal_values

logger = logging.getLogger(__name__)


class PLCModbusClient:
    def __init__(self, timeout: float = 2.0):
        self.timeout = timeout

    def _client(self, host: str, port: int) -> ModbusTcpClient:
        return ModbusTcpClient(host=host, port=port, timeout=self.timeout)

    def read_plc_registers(self, plc_id: int) -> Tuple[List[int], datetime]:
        definition = PLC_DEFINITIONS[plc_id]
        unit_id = definition["unit_id"]

        client = self._client(definition["host"], definition["port"])
        now = datetime.now(timezone.utc)
        try:
            if not client.connect():
                raise ConnectionError(f"No connection to PLC {plc_id}")

            rr = client.read_holding_registers(address=0, count=6, slave=unit_id)
            if rr.isError():
                raise RuntimeError(f"Modbus read error on PLC {plc_id}: {rr}")

            return rr.registers, now
        finally:
            client.close()

    def read_all(self) -> Tuple[Dict[int, List[int]], Dict[int, datetime]]:
        values: Dict[int, List[int]] = {}
        timestamps: Dict[int, datetime] = {}

        for plc_id in PLC_DEFINITIONS:
            try:
                plc_values, read_time = self.read_plc_registers(plc_id)
                values[plc_id] = plc_values
                timestamps[plc_id] = read_time
            except Exception as exc:  # pragma: no cover - defensive
                logger.warning("Failed to read PLC %s: %s", plc_id, exc)
                values[plc_id] = [0, 0, 0, 0, 0, 0]
                timestamps[plc_id] = datetime.now(timezone.utc)

        return values, timestamps

    def reset_plc(self, plc_id: int) -> bool:
        definition = PLC_DEFINITIONS[plc_id]
        unit_id = definition["unit_id"]
        reset_values = nominal_values(plc_id)

        client = self._client(definition["host"], definition["port"])
        try:
            if not client.connect():
                return False

            wr = client.write_registers(address=0, values=reset_values, slave=unit_id)
            return not wr.isError()
        except Exception as exc:  # pragma: no cover - defensive
            logger.error("Failed to reset PLC %s: %s", plc_id, exc)
            return False
        finally:
            client.close()
