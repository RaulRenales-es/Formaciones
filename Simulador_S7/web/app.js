const ws = new WebSocket(`ws://${window.location.host}/ws/state`);

ws.onmessage = (event) => {
  const state = JSON.parse(event.data);
  setLamp("pump_run", state.pump_run);
  setLamp("pump_fault", state.pump_fault);
  setLamp("valve_open", state.valve_open);
  setLamp("agitator_run", state.agitator_run);
  setLamp("alarm_low_level", state.alarm_low_level);
  setLamp("alarm_high_level", state.alarm_high_level);
  setLamp("emergency_stop", state.emergency_stop);

  document.getElementById("tank_level").textContent = state.tank_level;
  document.getElementById("agitator_speed").textContent = state.agitator_speed;
  document.getElementById("sp_level").value = state.level_setpoint;
  document.getElementById("sp_speed").value = state.speed_setpoint;
};

function setLamp(id, value) {
  const node = document.getElementById(id);
  node.classList.toggle("green", !!value);
  node.classList.toggle("red", !value);
}

async function sendCommand(command, value = null) {
  await fetch("/api/command", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ command, value }),
  });
}

function setLevelSetpoint() {
  const value = parseInt(document.getElementById("sp_level").value, 10);
  sendCommand("set_level_setpoint", value);
}

function setAgitatorSpeed() {
  const value = parseInt(document.getElementById("sp_speed").value, 10);
  sendCommand("set_agitator_speed", value);
}

function setEmergency(value) {
  sendCommand("set_emergency_stop", value);
}
