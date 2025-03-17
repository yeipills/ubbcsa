// app/javascript/components/MetricsChart.jsx
import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';
import consumer from '../channels/consumer';

const MetricsChart = ({ sessionId }) => {
  const [metrics, setMetrics] = useState([]);
  
  // Limitar el número de puntos de datos para evitar problemas de rendimiento
  const MAX_DATA_POINTS = 20;

  useEffect(() => {
    const channel = createChannel(sessionId);
    return () => channel.unsubscribe();
  }, [sessionId]);

  const createChannel = (sessionId) => {
    const channel = consumer.subscriptions.create(
      { channel: "MetricsChannel", sesion_id: sessionId },
      {
        received(data) {
          if (data.type === 'metric') {
            setMetrics(currentMetrics => {
              const newMetrics = [...currentMetrics, data];
              // Mantener solo los últimos MAX_DATA_POINTS puntos
              return newMetrics.slice(-MAX_DATA_POINTS);
            });
          }
        }
      }
    );
    return channel;
  };

  const chartData = {
    labels: metrics.map(m => {
      const date = new Date(m.timestamp);
      return date.toLocaleTimeString();
    }),
    datasets: [
      {
        label: 'CPU (%)',
        data: metrics.map(m => m.cpu),
        borderColor: 'rgb(75, 192, 192)',
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        tension: 0.1,
        fill: true
      },
      {
        label: 'Memoria (%)',
        data: metrics.map(m => m.memory),
        borderColor: 'rgb(153, 102, 255)',
        backgroundColor: 'rgba(153, 102, 255, 0.2)',
        tension: 0.1,
        fill: true
      }
    ]
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      y: {
        beginAtZero: true,
        max: 100,
        ticks: {
          color: 'rgba(255, 255, 255, 0.7)'
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        }
      },
      x: {
        ticks: {
          color: 'rgba(255, 255, 255, 0.7)'
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        }
      }
    },
    plugins: {
      legend: {
        labels: {
          color: 'rgba(255, 255, 255, 0.9)'
        }
      },
      tooltip: {
        mode: 'index',
        intersect: false
      }
    }
  };

  return (
    <div className="h-64">
      <Line data={chartData} options={chartOptions} />
    </div>
  );
};

export default MetricsChart;