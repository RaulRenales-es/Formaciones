import { useEffect, useMemo, useRef, useState } from 'react'
import PlantDiagram from './components/PlantDiagram'
import PlcCard from './components/PlcCard'

const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8000'
const WS_BASE = import.meta.env.VITE_WS_BASE || 'ws://localhost:8000/ws/status'

export default function App() {
  const [status, setStatus] = useState({ plant: 'solar_training_range', timestamp: null, plcs: [] })
  const [wsConnected, setWsConnected] = useState(false)
  const pollingRef = useRef(null)

  const sortedPlcs = useMemo(() => [...status.plcs].sort((a, b) => a.id - b.id), [status.plcs])

  const fetchStatus = async () => {
    const response = await fetch(`${API_BASE}/api/plants/status`)
    if (!response.ok) throw new Error('Error obtaining plant status')
    const data = await response.json()
    setStatus(data)
  }

  useEffect(() => {
    let socket
    let reconnectTimeout

    const startPolling = () => {
      if (!pollingRef.current) {
        pollingRef.current = setInterval(() => {
          fetchStatus().catch(() => {})
        }, 2000)
      }
    }

    const stopPolling = () => {
      if (pollingRef.current) {
        clearInterval(pollingRef.current)
        pollingRef.current = null
      }
    }

    const connectWebSocket = () => {
      socket = new WebSocket(WS_BASE)

      socket.onopen = () => {
        setWsConnected(true)
        stopPolling()
      }

      socket.onmessage = (event) => {
        setStatus(JSON.parse(event.data))
      }

      socket.onclose = () => {
        setWsConnected(false)
        startPolling()
        reconnectTimeout = setTimeout(connectWebSocket, 3000)
      }

      socket.onerror = () => {
        socket.close()
      }
    }

    fetchStatus().catch(() => {})
    connectWebSocket()

    return () => {
      if (socket) socket.close()
      if (reconnectTimeout) clearTimeout(reconnectTimeout)
      stopPolling()
    }
  }, [])

  const handleReset = async (plcId) => {
    await fetch(`${API_BASE}/api/reset/plc/${plcId}`, { method: 'POST' })
    await fetchStatus()
  }

  return (
    <main className="layout">
      <header>
        <h1>Solar OT Training Range</h1>
        <p>Laboratorio didáctico OT/ICS simulado para práctica Modbus TCP.</p>
        <p className="connection">Canal en tiempo real: {wsConnected ? 'WebSocket' : 'Polling 2s'}</p>
      </header>

      <PlantDiagram />

      <section className="cards-grid">
        {sortedPlcs.map((plc) => (
          <PlcCard key={plc.id} plc={plc} onReset={handleReset} />
        ))}
      </section>

      <footer>
        <small>Plant: {status.plant} · Actualización: {status.timestamp ? new Date(status.timestamp).toLocaleString() : 'N/A'}</small>
      </footer>
    </main>
  )
}
