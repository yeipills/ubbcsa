import consumer from "./consumer"

consumer.subscriptions.create({ channel: "LaboratorioChannel", session_id: sessionId }, {
  received(data) {
    if (data.type === 'metrics') {
      updateMetrics(data)
    } else if (data.type === 'log') {
      appendLog(data)
    }
  }
})