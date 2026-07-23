const express = require('express');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');
const agendamentoController = require('./controllers/agendamentoController');
const { authenticate } = require('./middlewares/authMiddleware');
const agendamentoRoutes = require('./routes/agendamentoRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes'); // Nova rota de feedbacks
const analiseRoutes = require('./routes/analiseRoutes');

// Cria a aplicação Express
const app = express();

// CORS explícito para funcionar com Flutter web (fetch API)
app.use(cors({
  origin: function (origin, callback) {
    // Permitir requests sem origin (server-to-server, mobile app, curl)
    if (!origin) return callback(null, true);
    // Permitir todos os origins para compatibilidade
    callback(null, true);
  },
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  credentials: true,
  maxAge: 86400,
}));

// Middlewares
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Middleware de logging para debug
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  if (req.method === 'POST' && req.url.includes('/signup')) {
    console.log('Body do cadastro:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Rotas públicas
app.use('/auth', authRoutes);
app.use('/feedback', feedbackRoutes); // Rota pública para visualizar feedbacks

app.post('/api/agendamentos/public', agendamentoController.criarAgendamento);
app.get('/api/agendamentos/public/booked-slots', agendamentoController.obterHorariosOcupados);
app.get('/api/manicures/public/by-city', authController.listarManicuresPorCidade);

// Rotas protegidas
app.use('/api/users', authenticate, userRoutes);
app.use('/api/agendamentos', authenticate, agendamentoRoutes);
app.use('/api/feedbacks', authenticate, feedbackRoutes); // Rota protegida para criar feedbacks
app.use('/api/analise', authenticate, analiseRoutes);

// Rota protegida de exemplo
app.get('/protegido', authenticate, (req, res) => {
  res.json({
    message: 'Rota protegida!',
    user: req.user
  });
});

// Rota raiz
app.get('/', (req, res) => {
  res.send('API está funcionando!');
});

module.exports = app;