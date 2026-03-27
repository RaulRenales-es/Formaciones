from __future__ import annotations

import asyncio
import json
import logging
import os
from typing import List

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from modbus_client import PLCModbusClient
from models import PlantStatus
from state_engine import PLC_DEFINITIONS, evaluate_plant

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger("backend")

POLL_INTERVAL = float(os.getenv("POLL_INTERVAL", "1"))

app = FastAPI(title="Solar OT Training Backend", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ConnectionManager:
    def __init__(self) -> None:
        self.connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self.connections.append(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        if websocket in self.connections:
            self.connections.remove(websocket)

    async def broadcast(self, payload: dict) -> None:
        stale = []
        for connection in self.connections:
            try:
                await connection.send_text(json.dumps(payload, default=str))
            except Exception:
                stale.append(connection)
        for connection in stale:
            self.disconnect(connection)


modbus_client = PLCModbusClient()
manager = ConnectionManager()
latest_status: PlantStatus | None = None


async def poll_loop() -> None:
    global latest_status
    while True:
        values, timestamps = await asyncio.to_thread(modbus_client.read_all)
        latest_status = evaluate_plant(values, timestamps)
        await manager.broadcast(latest_status.model_dump(mode="json"))
        await asyncio.sleep(POLL_INTERVAL)


@app.on_event("startup")
async def startup() -> None:
    asyncio.create_task(poll_loop())


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/api/plants/status")
async def get_status() -> dict:
    if latest_status is None:
        values, timestamps = await asyncio.to_thread(modbus_client.read_all)
        status = evaluate_plant(values, timestamps)
        return status.model_dump(mode="json")
    return latest_status.model_dump(mode="json")


@app.get("/api/plants/plc/{plc_id}")
async def get_plc(plc_id: int) -> dict:
    if plc_id not in PLC_DEFINITIONS:
        raise HTTPException(status_code=404, detail="PLC not found")

    status = await get_status()
    for plc in status["plcs"]:
        if plc["id"] == plc_id:
            return plc
    raise HTTPException(status_code=500, detail="PLC state unavailable")


@app.post("/api/reset/plc/{plc_id}")
async def reset_plc(plc_id: int) -> dict:
    if plc_id not in PLC_DEFINITIONS:
        raise HTTPException(status_code=404, detail="PLC not found")

    ok = await asyncio.to_thread(modbus_client.reset_plc, plc_id)
    if not ok:
        raise HTTPException(status_code=500, detail="PLC reset failed")

    values, timestamps = await asyncio.to_thread(modbus_client.read_all)
    status = evaluate_plant(values, timestamps)
    global latest_status
    latest_status = status
    await manager.broadcast(status.model_dump(mode="json"))

    return {
        "message": f"PLC-{plc_id} reset to nominal values",
        "plc_id": plc_id,
        "timestamp": status.timestamp,
    }


@app.websocket("/ws/status")
async def ws_status(websocket: WebSocket) -> None:
    await manager.connect(websocket)
    try:
        if latest_status is not None:
            await websocket.send_text(json.dumps(latest_status.model_dump(mode="json"), default=str))
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception as exc:  # pragma: no cover - defensive
        logger.warning("WebSocket closed unexpectedly: %s", exc)
        manager.disconnect(websocket)
