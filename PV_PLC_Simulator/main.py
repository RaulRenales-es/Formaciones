"""Aplicación principal FastAPI para la HMI y API REST del simulador."""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel

from simulator import SimulationEngine

app = FastAPI(title="PV PLC Simulator", version="1.0.0")
engine = SimulationEngine(interval_seconds=1.0)

templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")


class SolarSetPayload(BaseModel):
    irradiance_wm2: float | None = None
    panel_temp_c: float | None = None
    string_voltage_v: float | None = None
    string_current_a: float | None = None
    inverter_status: str | None = None


class BatterySetPayload(BaseModel):
    soc_percent: float | None = None
    battery_voltage_v: float | None = None
    battery_current_a: float | None = None
    charge_mode: str | None = None
    temperature_c: float | None = None


@app.on_event("startup")
def on_startup() -> None:
    """Inicia el loop de simulación al arrancar FastAPI."""
    engine.start()


@app.on_event("shutdown")
def on_shutdown() -> None:
    """Detiene el loop de simulación al cerrar FastAPI."""
    engine.stop()


@app.get("/", response_class=HTMLResponse)
def index(request: Request) -> Any:
    """Renderiza la HMI principal."""
    return templates.TemplateResponse("index.html", {"request": request})


@app.get("/api/plc/solar")
def get_plc_solar() -> dict[str, Any]:
    """Retorna estado actual del PLC Solar."""
    return engine.get_solar()


@app.get("/api/plc/battery")
def get_plc_battery() -> dict[str, Any]:
    """Retorna estado actual del PLC de Batería."""
    return engine.get_battery()


@app.post("/api/plc/solar/set")
def set_plc_solar(payload: SolarSetPayload) -> dict[str, Any]:
    """Permite escritura manual de valores para pruebas/demos."""
    data = payload.model_dump(exclude_none=True)
    return engine.set_solar(data)


@app.post("/api/plc/battery/set")
def set_plc_battery(payload: BatterySetPayload) -> dict[str, Any]:
    """Permite escritura manual de valores para pruebas/demos."""
    data = payload.model_dump(exclude_none=True)
    return engine.set_battery(data)
