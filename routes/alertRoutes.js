const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { getAlerts, createAlert } = require('../controllers/alertController');

// All alert endpoints require JWT authentication
router.use(protect);

// GET /api/alerts
router.get('/', getAlerts);

// POST /api/alerts
router.post('/', createAlert);

module.exports = router;
