"""Servidor S7 sobre python-snap7."""

from __future__ import annotations

import ctypes
import logging

import snap7

logger = logging.getLogger(__name__)

try:
    from snap7.types import srvAreaDB
except ImportError:  # Compatibilidad con versiones antiguas
    from snap7.type import srvAreaDB


class S7Server:
    """Wrapper del servidor S7 y área DB1 compartida."""

    def __init__(self, db_number: int, data: bytearray):
        self.db_number = db_number
        self._buffer = (ctypes.c_uint8 * len(data)).from_buffer(data)
        self.server = snap7.server.Server()

    def start(self, address: str = "0.0.0.0", tcp_port: int = 10200) -> None:
        self.server.register_area(srvAreaDB, self.db_number, self._buffer)
        self.server.start_to(address, tcp_port)
        logger.info("Servidor S7 iniciado en %s:%s (DB%s)", address, tcp_port, self.db_number)

    def stop(self) -> None:
        self.server.stop()
        logger.info("Servidor S7 detenido")
