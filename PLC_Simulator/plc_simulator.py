from __future__ import annotations

import signal
import threading
import time

from plc_server import create_plc_server
from register_map import PLC1_REGISTERS, PLC1_UNIT_ID, PLC2_REGISTERS, PLC2_UNIT_ID


def _run_plc(plc_name: str, unit_id: int, port: int, registers: dict[int, int]) -> None:
    """Inicia un PLC dentro de su propio hilo."""

    try:
        create_plc_server(
            plc_name=plc_name,
            unit_id=unit_id,
            host="0.0.0.0",
            port=port,
            registers=registers,
        )
    except Exception as exc:  # Captura defensiva para evitar caída silenciosa del hilo.
        print(f"[ERROR] {plc_name} falló en puerto {port}: {exc}")


def main() -> None:
    """Levanta ambos PLCs simulados y mantiene el proceso activo."""

    plc1_thread = threading.Thread(
        target=_run_plc,
        args=("PLC-1", PLC1_UNIT_ID, 15021, PLC1_REGISTERS.copy()),
        daemon=True,
    )
    plc2_thread = threading.Thread(
        target=_run_plc,
        args=("PLC-2", PLC2_UNIT_ID, 15022, PLC2_REGISTERS.copy()),
        daemon=True,
    )

    plc1_thread.start()
    print("[INFO] PLC-1 iniciado en puerto 15021")

    plc2_thread.start()
    print("[INFO] PLC-2 iniciado en puerto 15022")

    print("[INFO] Simulador en ejecución. Presiona CTRL+C para detener.")

    stop_event = threading.Event()

    def _handle_signal(_signum, _frame):
        print("\n[INFO] Señal de detención recibida. Cerrando simulador...")
        stop_event.set()

    signal.signal(signal.SIGINT, _handle_signal)
    signal.signal(signal.SIGTERM, _handle_signal)

    try:
        while not stop_event.is_set():
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\n[INFO] CTRL+C detectado. Cerrando simulador...")
    finally:
        # StartTcpServer es bloqueante por hilo; al terminar el proceso principal
        # (hilos daemon) se cierran los PLC simulados.
        print("[INFO] Simulador detenido.")


if __name__ == "__main__":
    main()
