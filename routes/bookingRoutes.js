const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
} = require('../controllers/bookingController');

// All booking endpoints require JWT authentication
router.use(protect);

// POST /api/bookings
router.post('/', createBooking);

// GET /api/bookings/my (must be declared before /:id)
router.get('/my', getMyBookings);

// GET /api/bookings/:id
router.get('/:id', getBookingById);

// PATCH /api/bookings/:id/cancel
router.patch('/:id/cancel', cancelBooking);

module.exports = router;
