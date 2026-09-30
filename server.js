const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const { notFoundHandler, errorHandler } = require('./middleware/errorMiddleware');

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS
app.use(cors());

// Enable JSON request parsing
app.use(express.json());

// Mount Authentication Routes
app.use('/api/auth', authRoutes);

// Root Endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to BusGo Backend API Server',
    version: '1.0.0',
  });
});

// Health-check Endpoint
app.get('/api/health', async (req, res, next) => {
  try {
    // Verify PostgreSQL connection
    const result = await db.query('SELECT 1 AS alive');

    if (result.rows && result.rows.length > 0) {
      return res.status(200).json({
        success: true,
        message: 'BusGo Backend Server is running smoothly',
        database: 'connected',
      });
    } else {
      throw new Error('Database ping failed');
    }
  } catch (error) {
    console.error('Health check database query error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'BusGo Backend Server health check failed',
      database: 'disconnected',
      error: error.message,
    });
  }
});

// Handle 404 Unknown Routes
app.use(notFoundHandler);

// Handle Unexpected Server Errors
app.use(errorHandler);

// Start Server
app.listen(PORT, () => {
  console.log(`BusGo Backend Server running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
});

module.exports = app;
