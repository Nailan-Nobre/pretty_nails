const supabase = require('../config/db')
const jwt = require('jsonwebtoken')
const { sendConfirmationEmail } = require('../services/emailService')

const JWT_SECRET = process.env.SUPABASE_JWT_SECRET || 'pretty-nails-secret'

// Cadastro direto na tabela manicures
exports.signUp = async (req, res) => {
  const { email, password, nome, telefone, estado, cidade } = req.body

  console.log('Dados recebidos no cadastro:', { email, nome, telefone, estado, cidade })

  try {
    if (!email || !email.includes('@')) {
      throw new Error('E-mail inválido')
    }

    if (!password || password.length < 6) {
      throw new Error('A senha deve ter pelo menos 6 caracteres')
    }

    if (!nome || nome.trim().length === 0) {
      throw new Error('O nome é obrigatório')
    }

    if (!telefone || telefone.trim().length === 0) {
      throw new Error('O telefone é obrigatório')
    }

    if (!estado || estado.trim().length === 0) {
      throw new Error('O estado é obrigatório')
    }

    if (!cidade || cidade.trim().length === 0) {
      throw new Error('A cidade é obrigatória')
    }

    const { data: existingUser } = await supabase.auth.admin.listUsers()
    const userExists = existingUser?.users?.some(u => u.email === email)
    if (userExists) {
      return res.status(400).json({
        success: false,
        error: 'Este e-mail já está cadastrado. Faça login ou use outro e-mail.'
      })
    }

    const { data: authData, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: false,
      user_metadata: { nome, telefone, estado, cidade, tipo: 'MANICURE' }
    })

    if (createError) throw createError

    const confirmToken = jwt.sign(
      { userId: authData.user.id, email },
      JWT_SECRET,
      { expiresIn: '24h' }
    )

    const backendUrl = getBackendUrl(req)
    const frontendUrl = getFrontendUrl()
    const confirmLink = `${backendUrl}/auth/confirm?token=${confirmToken}&redirect=${encodeURIComponent(frontendUrl + '/confirmacao.html')}`

    const emailSent = await sendConfirmationEmail(email, nome, confirmLink)

    if (!emailSent) {
      console.error('Falha ao enviar e-mail de confirmação para:', email)
    }

    res.json({
      success: true,
      message: 'Cadastro realizado! Verifique sua caixa de e-mail para confirmar sua conta.'
    })

  } catch (error) {
    console.error("Erro no cadastro:", error)

    if (error.message?.toLowerCase().includes('rate limit')) {
      return res.status(429).json({
        success: false,
        error: 'Muitas tentativas. Aguarde alguns minutos e tente novamente.'
      })
    }

    if (error.message?.includes('already') || error.message?.includes('já existe')) {
      return res.status(400).json({
        success: false,
        error: 'Este e-mail já está cadastrado. Faça login ou use outro e-mail.'
      })
    }

    res.status(400).json({
      success: false,
      error: error.message || 'Erro ao processar cadastro. Tente novamente.'
    })
  }
}

// Confirmar e-mail
exports.confirmEmail = async (req, res) => {
  const { token, redirect } = req.query

  const frontendUrl = getFrontendUrl()
  const redirectBase = redirect || `${frontendUrl}/confirmacao.html`

  try {
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token não fornecido.' })
    }

    const decoded = jwt.verify(token, JWT_SECRET)

    const { error } = await supabase.auth.admin.updateUserById(decoded.userId, {
      email_confirm: true
    })

    if (error) throw error

    const separator = redirectBase.includes('?') ? '&' : '?'
    return res.redirect(`${redirectBase}${separator}status=success`)
  } catch (error) {
    const separator = redirectBase.includes('?') ? '&' : '?'
    if (error.name === 'TokenExpiredError') {
      return res.redirect(`${redirectBase}${separator}status=expired`)
    }
    if (error.name === 'JsonWebTokenError') {
      return res.redirect(`${redirectBase}${separator}status=invalid`)
    }
    return res.redirect(`${redirectBase}${separator}status=error`)
  }
}

// Reenviar e-mail de verificação
exports.resendConfirmation = async (req, res) => {
  const { email } = req.body

  try {
    if (!email || !email.includes('@')) {
      throw new Error('E-mail inválido')
    }

    const { data: existingUser } = await supabase.auth.admin.listUsers()
    const user = existingUser?.users?.find(u => u.email === email)

    if (!user) {
      return res.json({ success: true, message: 'Se o e-mail estiver cadastrado, você receberá a confirmação.' })
    }

    if (user.email_confirmed_at) {
      return res.json({ success: true, message: 'E-mail já confirmado. Você pode fazer login.' })
    }

    const confirmToken = jwt.sign(
      { userId: user.id, email },
      JWT_SECRET,
      { expiresIn: '24h' }
    )

    const backendUrl = getBackendUrl(req)
    const frontendUrl = getFrontendUrl()
    const confirmLink = `${backendUrl}/auth/confirm?token=${confirmToken}&redirect=${encodeURIComponent(frontendUrl + '/confirmacao.html')}`
    const nome = user.user_metadata?.nome || 'usuária'

    const emailSent = await sendConfirmationEmail(email, nome, confirmLink)

    if (!emailSent) {
      throw new Error('Falha ao enviar e-mail')
    }

    res.json({ success: true, message: 'E-mail de confirmação reenviado. Verifique sua caixa de entrada.' })
  } catch (error) {
    console.error("Erro ao reenviar confirmação:", error)
    res.status(400).json({
      success: false,
      error: 'Erro ao reenviar e-mail. Tente novamente em alguns minutos.'
    })
  }
}

// Login
exports.login = async (req, res) => {
  const { email, password } = req.body

  try {
    if (!email || !email.includes('@')) {
      throw new Error('E-mail inválido')
    }

    if (!password) {
      throw new Error('Informe sua senha')
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    if (error) {
      if (error.message?.includes('Invalid login') || error.message?.includes('invalid_credentials')) {
        throw new Error('E-mail ou senha incorretos. Verifique e tente novamente.')
      }
      if (error.message?.includes('Email not confirmed')) {
        throw new Error('E-mail ainda não confirmado. Verifique sua caixa de entrada ou reenvie a confirmação.')
      }
      throw error
    }

    if (!data.user.email_confirmed_at) {
      throw new Error('E-mail ainda não confirmado. Verifique sua caixa de entrada.')
    }

    const { data: userData, error: profileError } = await supabase
      .from('manicures')
      .select('*')
      .eq('id', data.user.id)
      .single()

    let manicureProfile = userData

    if (profileError || !manicureProfile) {
      const metadata = data.user.user_metadata || {}
      const nomeBase = metadata.nome || data.user.email?.split('@')[0] || 'manicure'
      const slug = `${slugify(nomeBase)}-${data.user.id.slice(0, 8)}`

      const { data: createdProfile, error: createProfileError } = await supabase
        .from('manicures')
        .insert({
          id: data.user.id,
          email: data.user.email,
          nome: nomeBase,
          telefone: metadata.telefone || null,
          estado: metadata.estado || null,
          cidade: metadata.cidade || null,
          slug,
          ativa: true,
          bio: ''
        })
        .select()
        .single()

      if (createProfileError) throw createProfileError

      manicureProfile = createdProfile
    }

    res.json({
      success: true,
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: {
        ...data.user,
        ...manicureProfile,
        tipo: 'MANICURE'
      }
    })

  } catch (error) {
    console.error("Erro no login:", error)
    res.status(401).json({
      success: false,
      error: error.message || 'Erro ao fazer login. Tente novamente.'
    })
  }
}

// Obter perfil
exports.getUserProfile = async (req, res) => {
  try {
    const { data: userData, error } = await supabase
      .from('manicures')
      .select('*')
      .eq('id', req.user.id)
      .single()

    if (error) throw error

    res.json({
      success: true,
      user: {
        ...userData,
        tipo: 'MANICURE'
      }
    })

  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Erro ao carregar perfil",
      details: error.message
    })
  }
}

// Buscar por ID
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data: user, error } = await supabase
      .from('manicures')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !user) throw error || new Error('Usuário não encontrado');

    res.json(user);
  } catch (error) {
    res.status(404).json({ error: 'Usuário não encontrado' });
  }
}

// Buscar manicure por slug para a tela pública de agendamento
exports.getManicureBySlug = async (req, res) => {
  try {
    const { slug } = req.params

    const { data: manicure, error } = await supabase
      .from('manicures')
      .select('id, email, nome, foto, telefone, estado, cidade, bio, slug, estrelas, ativa, dias_trabalho, horarios, servicos, regras, created_at, updated_at')
      .eq('slug', slug)
      .single()

    if (error || !manicure) {
      return res.status(404).json({
        success: false,
        error: 'Manicure não encontrada'
      })
    }

    res.json({
      success: true,
      manicure
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro ao carregar manicure',
      details: error.message
    })
  }
}

// Atualizar perfil
exports.updateProfile = async (req, res) => {
  const updates = req.body

  try {
    const { data, error } = await supabase
      .from('manicures')
      .update(updates)
      .eq('id', req.user.id)
      .select()

    if (error) throw error

    res.json({
      success: true,
      user: {
        ...data[0],
        tipo: 'MANICURE'
      }
    })

  } catch (error) {
    res.status(400).json({
      success: false,
      error: "Erro ao atualizar perfil",
      details: error.message
    })
  }
}

// Refresh token
exports.refreshToken = async (req, res) => {
  const { refresh_token } = req.body

  try {
    if (!refresh_token) {
      return res.status(400).json({ success: false, error: 'Refresh token não fornecido' })
    }

    const { data, error } = await supabase.auth.refreshSession({
      refresh_token
    })

    if (error) throw error

    res.json({
      success: true,
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    })

  } catch (error) {
    console.error("Erro ao refresh token:", error)
    res.status(401).json({
      success: false,
      error: 'Sessão expirada. Faça login novamente.'
    })
  }
}

function slugify(text) {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

async function gerarSlugUnico(client, base) {
  let slug = base
  let tentativa = 0

  while (true) {
    const { data, error } = await client
      .from('manicures')
      .select('id')
      .eq('slug', slug)
      .maybeSingle()

    if (error) throw error
    if (!data) return slug

    tentativa += 1
    slug = `${base}-${tentativa}`
  }
}

function getBackendUrl(req) {
  if (req) {
    return `${req.protocol}://${req.get('host')}`
  }
  const url = String(process.env.BACKEND_URL || '').replace(/\/$/, '')
  if (!url || url === '*' || !url.startsWith('http')) {
    return 'http://localhost:3000'
  }
  return url
}

function getFrontendUrl() {
  const url = String(process.env.FRONTEND_URL || '').replace(/\/$/, '')
  if (!url || url === '*' || !url.startsWith('http')) {
    return 'https://pretty-nails-app.vercel.app'
  }
  return url
}

