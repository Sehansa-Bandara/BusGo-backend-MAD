const express = require('express');
const router = express.Router();
const {
  registerUser,
  requestSignupOtp,
  verifySignupOtp,
  resendSignupOtp,
  loginUser,
  getMe,
  updateProfile,
  forgotPassword,
  resetPassword,
  setupAdminAccount,
  saveAppLock
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

// POST /api/auth/register (Direct Signup)
router.post('/register', registerUser);

// POST /api/auth/register-request (Request Email OTP)
router.post('/register-request', requestSignupOtp);

// POST /api/auth/verify-otp (Verify Email OTP & Complete Signup)
router.post('/verify-otp', verifySignupOtp);

// POST /api/auth/resend-otp (Resend Email OTP Code with 60s cooldown)
router.post('/resend-otp', resendSignupOtp);

// POST /api/auth/login
router.post('/login', loginUser);

// POST /api/auth/forgot-password
router.post('/forgot-password', forgotPassword);

// POST /api/auth/reset-password
router.post('/reset-password', resetPassword);

// POST /api/auth/setup-admin
router.post('/setup-admin', setupAdminAccount);

// POST /api/auth/app-lock
router.post('/app-lock', protect, saveAppLock);

// GET /api/auth/me
router.get('/me', protect, getMe);

// PUT /api/auth/me
router.put('/me', protect, updateProfile);

module.exports = router;
