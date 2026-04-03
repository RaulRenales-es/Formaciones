const solarCardsContainer = document.getElementById("solar-cards");
const batteryCardsContainer = document.getElementById("battery-cards");

const solarStatusDot = document.getElementById("solar-status-dot");
const solarStatusText = document.getElementById("solar-status-text");
const batteryStatusDot = document.getElementById("battery-status-dot");
const batteryStatusText = document.getElementById("battery-status-text");

function formatValue(key, value) {
  if (typeof value === "number") {
    if (key.includes("percent")) return `${value.toFixed(1)} %`;
    if (key.includes("temp") || key.includes("temperature")) return `${value.toFixed(1)} °C`;
    if (key.includes("voltage")) return `${value.toFixed(1)} V`;
    if (key.includes("current")) return `${value.toFixed(1)} A`;
    if (key.includes("irradiance")) return `${value.toFixed(1)} W/m²`;
    return value.toFixed(2);
  }
  if (typeof value === "boolean") return value ? "TRUE" : "FALSE";
  return String(value);
}

function titleFromKey(key) {
  return key.replaceAll("_", " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function renderCards(container, data) {
  container.innerHTML = "";

  Object.entries(data).forEach(([key, value]) => {
    const card = document.createElement("div");
    card.className = "card";

    const label = document.createElement("div");
    label.className = "label";
    label.textContent = titleFromKey(key);

    const val = document.createElement("div");
    val.className = "value";
    val.textContent = formatValue(key, value);

    card.appendChild(label);
    card.appendChild(val);
    container.appendChild(card);
  });
}

function updateStatus(alarm, dotEl, textEl) {
  dotEl.classList.remove("status-ok", "status-alarm");
  if (alarm) {
    dotEl.classList.add("status-alarm");
    textEl.textContent = "ALARMA";
  } else {
    dotEl.classList.add("status-ok");
    textEl.textContent = "NORMAL";
  }
}

async function fetchPLCData() {
  try {
    const [solarRes, batteryRes] = await Promise.all([
      fetch("/api/plc/solar"),
      fetch("/api/plc/battery"),
    ]);

    if (!solarRes.ok || !batteryRes.ok) {
      throw new Error("Error consultando API");
    }

    const solar = await solarRes.json();
    const battery = await batteryRes.json();

    renderCards(solarCardsContainer, solar);
    renderCards(batteryCardsContainer, battery);

    updateStatus(Boolean(solar.alarm), solarStatusDot, solarStatusText);
    updateStatus(Boolean(battery.alarm), batteryStatusDot, batteryStatusText);
  } catch (err) {
    solarStatusDot.classList.remove("status-ok");
    batteryStatusDot.classList.remove("status-ok");
    solarStatusDot.classList.add("status-alarm");
    batteryStatusDot.classList.add("status-alarm");
    solarStatusText.textContent = "ERROR";
    batteryStatusText.textContent = "ERROR";
    console.error("Fallo al actualizar HMI:", err);
  }
}

fetchPLCData();
setInterval(fetchPLCData, 1000);
