// Express Server Entry Point
const express = require('express');

const app = express();
const PORT = process.env.PORT || 5000;

app.get('/', (req, res) => {
  res.send('BusGo Backend API is running...');
});

// Server listener placeholder
