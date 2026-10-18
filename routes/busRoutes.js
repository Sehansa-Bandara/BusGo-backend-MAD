const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getAllBuses,
  getMyDriverBuses,
  getBusById,
  searchBuses,
  getBusStops,
  getRouteDetails,
  getBusesByRoute,
  getSeatAvailability,
  getBusSeats,
  getBusLocation,
  createBus,
} = require('../controllers/busController');

// GET /api/buses
router.get('/', getAllBuses);

// GET /api/buses/my
router.get('/my', protect, getMyDriverBuses);

// POST /api/buses
router.post('/', protect, createBus);

// GET /api/buses/search (declared before /:id)
router.get('/search', searchBuses);

// GET /api/buses/routes/:routeNumber (declared before /:id)
router.get('/routes/:routeNumber', getRouteDetails);

// GET /api/buses/routes/:routeNumber/buses (declared before /:id)
router.get('/routes/:routeNumber/buses', getBusesByRoute);

// GET /api/buses/:id/seats/availability (declared before /:id)
router.get('/:id/seats/availability', getSeatAvailability);

// GET /api/buses/:id/seats (declared before /:id)
router.get('/:id/seats', getBusSeats);

// GET /api/buses/:id/stops (declared before /:id)
router.get('/:id/stops', getBusStops);

// GET /api/buses/:id/location (declared before /:id)
router.get('/:id/location', protect, getBusLocation);

// GET /api/buses/:id
router.get('/:id', getBusById);

module.exports = router;
