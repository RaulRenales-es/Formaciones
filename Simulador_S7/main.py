"""Punto único de arranque del Simulador S7."""

from __future__ import annotations

import logging
import threading
import time

import uvicorn

from api import RuntimeContext, create_app
from memory_map import S7MemoryMap
from process_model import ProcessModel
from s7_server import S7Server

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("simulador_s7")


class SimulationEngine:
    def __init__(self, runtime: RuntimeContext, period_s: float = 0.5):
        self.runtime = runtime
        self.period_s = period_s
        self._running = False
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()
        logger.info("Bucle de simulación iniciado")

    def stop(self) -> None:
        self._running = False
        if self._thread:
            self._thread.join(timeout=2)
        logger.info("Bucle de simulación detenido")

    def _loop(self) -> None:
        while self._running:
            with self.runtime.lock:
                commands = self.runtime.memory_map.read_commands()
                self.runtime.model.apply_commands(commands)
                self.runtime.model.step()
                self.runtime.memory_map.write_state(self.runtime.model.snapshot())
            time.sleep(self.period_s)


def main() -> None:
    model = ProcessModel()
    memory_map = S7MemoryMap()
    lock = threading.Lock()
    runtime = RuntimeContext(model=model, memory_map=memory_map, lock=lock)

    s7 = S7Server(db_number=1, data=memory_map.db)
    s7.start(address="0.0.0.0", tcp_port=10200)

    engine = SimulationEngine(runtime)
    engine.start()

    app = create_app(runtime)

    try:
        uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
    finally:
        engine.stop()
        s7.stop()


if __name__ == "__main__":
    main()
