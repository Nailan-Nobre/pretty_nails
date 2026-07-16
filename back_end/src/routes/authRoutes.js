const express = require('express');
const router = express.Router();
const {
  signUp,
  confirmEmail,
  resendConfirmation,
  login,
  getUserProfile,
  getUserById,
  getManicureBySlug,
  updateProfile,
  refreshToken,
  savePlayerId,
  changeEmail,
  changePassword,
  deleteAccount,
  sendSupportMessage,
  forgotPassword,
  resetPassword,
  resetPasswordPage
} = require('../controllers/authController');
const uploadController = require('../controllers/uploadController');
const { authenticate } = require('../middlewares/authMiddleware');

// Rotas públicas
router.post('/signup', signUp);
router.get('/confirm', confirmEmail);
router.post('/resend-confirmation', resendConfirmation);
router.post('/login', login);
router.post('/refresh', refreshToken);
router.post('/forgot-password', forgotPassword);
router.get('/reset-password', resetPasswordPage);
router.post('/reset-password', resetPassword);
router.get('/usuario/:id', getUserById);
router.get('/manicure/:slug', getManicureBySlug);

// Rotas protegidas
router.put('/profile', authenticate, updateProfile);
router.post('/upload', authenticate, uploadController.uploadImagem);
router.get('/profile', authenticate, getUserProfile);
router.post('/player-id', authenticate, savePlayerId);
router.post('/change-email', authenticate, changeEmail);
router.post('/change-password', authenticate, changePassword);
router.post('/delete-account', authenticate, deleteAccount);
router.post('/support', authenticate, sendSupportMessage);

module.exports = router;