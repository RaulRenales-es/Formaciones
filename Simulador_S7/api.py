"""Capa web (FastAPI + WebSocket + estáticos)."""

from __future__ import annotations

import asyncio
import logging
import threading
from pathlib import Path

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from process_model import ProcessModel

logger = logging.getLogger(__name__)


class CommandRequest(BaseModel):
    command: str
    value: int | bool | None = None


class RuntimeContext:
    """Estado compartido entre simulación, API y servidor S7."""

    def __init__(self, model: ProcessModel, memory_map, lock: threading.Lock):
        self.model = model
        self.memory_map = memory_map
        self.lock = lock


class WebSocketHub:
    def __init__(self) -> None:
        self._clients: set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._clients.add(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        self._clients.discard(websocket)

    async def broadcast(self, payload: dict) -> None:
        stale = []
        for ws in list(self._clients):
            try:
                await ws.send_json(payload)
            except Exception:
                stale.append(ws)
        for ws in stale:
            self.disconnect(ws)


def create_app(runtime: RuntimeContext) -> FastAPI:
    app = FastAPI(title="Simulador S7")
    hub = WebSocketHub()
    web_dir = Path(__file__).parent / "web"
    app.mount("/assets", StaticFiles(directory=web_dir), name="assets")

    @app.get("/")
    async def index() -> FileResponse:
        return FileResponse(web_dir / "index.html")

    @app.post("/api/command")
    async def send_command(req: CommandRequest) -> dict:
        command_data: dict = {}

        if req.command in {"start_pump", "stop_pump", "open_valve", "close_valve", "reset_alarms"}:
            command_data[req.command] = True
        elif req.command == "set_level_setpoint" and req.value is not None:
            command_data["level_setpoint"] = int(req.value)
        elif req.command == "set_agitator_speed" and req.value is not None:
            command_data["agitator_speed"] = int(req.value)
        elif req.command == "set_emergency_stop" and req.value is not None:
            command_data["emergency_stop"] = bool(req.value)

        with runtime.lock:
            if "emergency_stop" in command_data:
                runtime.model.state.emergency_stop = bool(command_data["emergency_stop"])
                command_data.pop("emergency_stop")
            runtime.model.apply_commands(command_data)
            runtime.memory_map.write_state(runtime.model.snapshot())

        logger.info("Comando web recibido: %s", req.command)
        return {"status": "ok"}

    @app.websocket("/ws/state")
    async def ws_state(websocket: WebSocket) -> None:
        await hub.connect(websocket)
        try:
            while True:
                with runtime.lock:
                    state = runtime.model.snapshot()
                await websocket.send_json(state)
                await asyncio.sleep(0.3)
        except WebSocketDisconnect:
            hub.disconnect(websocket)

    @app.on_event("startup")
    async def startup_event() -> None:
        async def broadcaster() -> None:
            while True:
                with runtime.lock:
                    state = runtime.model.snapshot()
                await hub.broadcast(state)
                await asyncio.sleep(1.0)

        app.state.broadcast_task = asyncio.create_task(broadcaster())

    @app.on_event("shutdown")
    async def shutdown_event() -> None:
        app.state.broadcast_task.cancel()

    return app
