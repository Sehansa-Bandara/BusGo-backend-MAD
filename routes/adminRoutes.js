const express = require('express');
const router = express.Router();
const { protect, requireAdmin } = require('../middleware/authMiddleware');
const {
  getAdminStats,
  getAdminItems,
  createAdminItem,
  deleteAdminItem,
  resetDatabase,
  getAdminIncidents,
} = require('../controllers/adminController');

// All admin endpoints require JWT protection + Admin role authorization
router.use(protect);
router.use(requireAdmin);

// GET /api/admin/stats
router.get('/stats', getAdminStats);

// GET /api/admin/items
router.get('/items', getAdminItems);

// POST /api/admin/items
router.post('/items', createAdminItem);

// DELETE /api/admin/items/:id
router.delete('/items/:id', deleteAdminItem);

// POST /api/admin/danger/reset
router.post('/danger/reset', resetDatabase);

// GET /api/admin/incidents
router.get('/incidents', getAdminIncidents);

module.exports = router;
