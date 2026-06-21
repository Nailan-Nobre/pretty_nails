const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedbackController');
const { authenticate } = require('../middlewares/authMiddleware');

// Rota pública para criar feedback (cliente avalia após conclusão)
router.post('/', feedbackController.criarFeedback);

// Rota pública para ver feedbacks de uma manicure
router.get('/manicure/:manicureId', feedbackController.getFeedbacksPorManicure);

// Rota pública para ver detalhes do agendamento (para página de avaliação)
router.get('/agendamento/:id', feedbackController.getAgendamentoComFeedback);

module.exports = router;