function formatRange(parameter) {
  if (parameter.valid_values) {
    return `{${parameter.valid_values.join(', ')}}`
  }
  if (!parameter.range) {
    return '-'
  }
  return `[${parameter.range[0]}, ${parameter.range[1]}]`
}

export default function PlcCard({ plc, onReset }) {
  const isAltered = plc.state === 'ALTERED'

  return (
    <article className={`plc-card ${isAltered ? 'altered' : 'nominal'}`}>
      <div className="plc-header">
        <div>
          <h2>{plc.name}</h2>
          <p>{plc.host}:{plc.port}</p>
        </div>
        <div className={`lamp ${plc.lamp === 'RED' ? 'red' : 'green'}`} aria-label={`Lamp ${plc.lamp}`} />
      </div>

      <div className="badges">
        <span className={`badge ${isAltered ? 'badge-red' : 'badge-green'}`}>
          {isAltered ? 'ATTACK / MANIPULATED' : 'NORMAL'}
        </span>
        <span className="badge badge-muted">Estado: {plc.state}</span>
      </div>

      <table>
        <thead>
          <tr>
            <th>Registro</th>
            <th>Nombre</th>
            <th>Actual</th>
            <th>Nominal</th>
            <th>Rango</th>
          </tr>
        </thead>
        <tbody>
          {plc.parameters.map((parameter) => (
            <tr key={`${plc.id}-${parameter.register}`} className={parameter.in_range ? '' : 'row-alert'}>
              <td>HR{parameter.register}</td>
              <td>{parameter.name}</td>
              <td>{parameter.value}</td>
              <td>{parameter.nominal}</td>
              <td>{formatRange(parameter)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <div className="card-footer">
        <small>Última lectura: {plc.last_read ? new Date(plc.last_read).toLocaleString() : 'N/A'}</small>
        <button type="button" onClick={() => onReset(plc.id)}>Reset PLC</button>
      </div>
    </article>
  )
}
