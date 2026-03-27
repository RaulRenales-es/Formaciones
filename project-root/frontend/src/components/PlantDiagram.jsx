export default function PlantDiagram() {
  return (
    <section className="diagram-card">
      <svg viewBox="0 0 720 240" className="plant-svg" role="img" aria-label="Diagrama de planta solar">
        <rect x="20" y="170" width="680" height="40" fill="#313f52" rx="6" />

        <rect x="60" y="90" width="160" height="70" fill="#1f3a5a" rx="8" />
        <line x1="60" y1="120" x2="220" y2="120" stroke="#5fa7ff" strokeWidth="2" />
        <line x1="100" y1="90" x2="100" y2="160" stroke="#5fa7ff" strokeWidth="2" />
        <line x1="140" y1="90" x2="140" y2="160" stroke="#5fa7ff" strokeWidth="2" />
        <line x1="180" y1="90" x2="180" y2="160" stroke="#5fa7ff" strokeWidth="2" />
        <text x="95" y="80" fill="#d6e3f2">Paneles A</text>

        <rect x="280" y="90" width="120" height="70" fill="#37495f" rx="8" />
        <text x="300" y="130" fill="#d6e3f2">Inversor</text>

        <rect x="470" y="80" width="120" height="80" fill="#364f44" rx="8" />
        <text x="486" y="124" fill="#d7f9de">Batería B</text>

        <polyline points="220,125 280,125 400,125 470,120" fill="none" stroke="#a8c7ff" strokeWidth="4" />
        <line x1="590" y1="120" x2="660" y2="120" stroke="#ffd764" strokeWidth="4" />
        <rect x="660" y="85" width="34" height="70" fill="#7b5b1a" rx="4" />
        <text x="650" y="76" fill="#ffe8b0">Red</text>
      </svg>
    </section>
  )
}
