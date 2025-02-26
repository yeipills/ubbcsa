// app/javascript/components/MetricsChart.jsx
import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';

const MetricsChart = ({ sessionId }) => {
  const [metrics, setMetrics] = useState([]);

  useEffect(() => {
    const channel = createChannel(sessionId);
    return () => channel.unsubscribe();
  }, [sessionId]);

  const createChannel = (sessionId) => {
    const channel = consumer.subscriptions.create(
      { channel: "LaboratorioChannel", session_id: sessionId },
      {
        received(data) {
          setMetrics(currentMetrics => [...currentMetrics, data]);
        }
      }
    );
    return channel;
  };

  const chartData = {
    labels: metrics.map(m => m.timestamp),
    datasets: [
      {
        label: 'CPU Usage',
        data: metrics.map(m => m.cpu_usage),
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      },
      {
        label: 'Memory Usage',
        data: metrics.map(m => m.memory_usage),
        borderColor: 'rgb(153, 102, 255)',
        tension: 0.1
      }
    ]
  };

  return <Line data={chartData} options={chartOptions} />;
};

export default MetricsChart;