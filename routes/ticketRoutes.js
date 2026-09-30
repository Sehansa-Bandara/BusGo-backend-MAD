const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getMyTickets,
  getTicketById,
  getTicketByNumber,
} = require('../controllers/ticketController');

// All ticket endpoints require authentication
router.use(protect);

// GET /api/tickets/my (declared before /:id)
router.get('/my', getMyTickets);

// GET /api/tickets/number/:ticketNumber (declared before /:id)
router.get('/number/:ticketNumber', getTicketByNumber);

// GET /api/tickets/:id
router.get('/:id', getTicketById);

module.exports = router;
