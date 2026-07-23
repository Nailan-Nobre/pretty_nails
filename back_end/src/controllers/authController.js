const supabase = require('../config/db')
const jwt = require('jsonwebtoken')
const { sendConfirmationEmail, sendSupportEmail, sendPasswordResetEmail } = require('../services/emailService')

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

// Listar manicures por cidade (rota pública)
exports.listarManicuresPorCidade = async (req, res) => {
  try {
    const { cidade } = req.query

    if (!cidade || cidade.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Cidade é obrigatória'
      })
    }

    const { data: manicures, error } = await supabase
      .from('manicures')
      .select('id, nome, foto, cidade, estado, slug, estrelas, bio')
      .eq('cidade', cidade.trim())
      .eq('ativa', true)
      .order('estrelas', { ascending: false })

    if (error) throw error

    res.json({
      success: true,
      manicures: manicures || []
    })
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erro ao buscar manicures',
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

// Salvar OneSignal player ID
exports.savePlayerId = async (req, res) => {
  const { player_id } = req.body

  try {
    if (!player_id) {
      return res.status(400).json({ success: false, error: 'Player ID não fornecido' })
    }

    const { error } = await supabase
      .from('manicures')
      .update({ onesignal_player_id: player_id })
      .eq('id', req.user.id)

    if (error) throw error

    res.json({ success: true, message: 'Player ID salvo com sucesso' })
  } catch (error) {
    console.error('Erro ao salvar player ID:', error)
    res.status(500).json({
      success: false,
      error: 'Erro ao salvar player ID'
    })
  }
}

// Alterar e-mail
exports.changeEmail = async (req, res) => {
  const { newEmail, password } = req.body
  const userId = req.user.id

  try {
    if (!newEmail || !newEmail.includes('@')) {
      return res.status(400).json({ success: false, error: 'E-mail inválido' })
    }

    if (!password) {
      return res.status(400).json({ success: false, error: 'Informe sua senha atual' })
    }

    // Verificar senha atual
    const { data: userData } = await supabase.auth.admin.getUserById(userId)
    if (!userData?.user?.email) {
      return res.status(400).json({ success: false, error: 'Usuário não encontrado' })
    }

    // Tentar fazer login com a senha atual para validar
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: userData.user.email,
      password: password
    })

    if (signInError) {
      return res.status(400).json({ success: false, error: 'Senha incorreta' })
    }

    // Verificar se o novo e-mail já está em uso
    const { data: existingUsers } = await supabase.auth.admin.listUsers()
    const emailInUse = existingUsers?.users?.some(u => u.email === newEmail && u.id !== userId)
    if (emailInUse) {
      return res.status(400).json({ success: false, error: 'Este e-mail já está em uso' })
    }

    // Atualizar e-mail no Supabase Auth
    const { error: updateError } = await supabase.auth.admin.updateUserById(userId, {
      email: newEmail,
      email_confirm: false
    })

    if (updateError) throw updateError

    // Atualizar e-mail na tabela manicures
    const { error: profileError } = await supabase
      .from('manicures')
      .update({ email: newEmail })
      .eq('id', userId)

    if (profileError) throw profileError

    // Enviar e-mail de confirmação para o novo e-mail
    const confirmToken = jwt.sign(
      { userId, email: newEmail },
      JWT_SECRET,
      { expiresIn: '24h' }
    )

    const backendUrl = getBackendUrl(req)
    const frontendUrl = getFrontendUrl()
    const confirmLink = `${backendUrl}/auth/confirm?token=${confirmToken}&redirect=${encodeURIComponent(frontendUrl + '/confirmacao.html')}`
    const nome = userData.user.user_metadata?.nome || 'usuária'

    await sendConfirmationEmail(newEmail, nome, confirmLink)

    res.json({
      success: true,
      message: 'E-mail alterado. Verifique sua caixa de entrada para confirmar o novo e-mail.'
    })

  } catch (error) {
    console.error('Erro ao alterar e-mail:', error)
    res.status(500).json({
      success: false,
      error: error.message || 'Erro ao alterar e-mail'
    })
  }
}

// Alterar senha
exports.changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body
  const userId = req.user.id

  try {
    if (!currentPassword) {
      return res.status(400).json({ success: false, error: 'Informe sua senha atual' })
    }

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ success: false, error: 'A nova senha deve ter pelo menos 6 caracteres' })
    }

    // Verificar senha atual fazendo login
    const { data: userData } = await supabase.auth.admin.getUserById(userId)
    if (!userData?.user?.email) {
      return res.status(400).json({ success: false, error: 'Usuário não encontrado' })
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: userData.user.email,
      password: currentPassword
    })

    if (signInError) {
      return res.status(400).json({ success: false, error: 'Senha atual incorreta' })
    }

    // Atualizar senha
    const { error: updateError } = await supabase.auth.admin.updateUserById(userId, {
      password: newPassword
    })

    if (updateError) throw updateError

    res.json({
      success: true,
      message: 'Senha alterada com sucesso'
    })

  } catch (error) {
    console.error('Erro ao alterar senha:', error)
    res.status(500).json({
      success: false,
      error: error.message || 'Erro ao alterar senha'
    })
  }
}

// Excluir conta
exports.deleteAccount = async (req, res) => {
  const { password } = req.body
  const userId = req.user.id

  try {
    if (!password) {
      return res.status(400).json({ success: false, error: 'Informe sua senha para confirmar' })
    }

    // Verificar senha fazendo login
    const { data: userData } = await supabase.auth.admin.getUserById(userId)
    if (!userData?.user?.email) {
      return res.status(400).json({ success: false, error: 'Usuário não encontrado' })
    }

    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: userData.user.email,
      password: password
    })

    if (signInError) {
      return res.status(400).json({ success: false, error: 'Senha incorreta' })
    }

    // Deletar dados da tabela manicures (cascata deve cuidar dos agendamentos)
    const { error: deleteProfileError } = await supabase
      .from('manicures')
      .delete()
      .eq('id', userId)

    if (deleteProfileError) throw deleteProfileError

    // Deletar usuário do Supabase Auth
    const { error: deleteAuthError } = await supabase.auth.admin.deleteUser(userId)

    if (deleteAuthError) throw deleteAuthError

    res.json({
      success: true,
      message: 'Conta excluída com sucesso'
    })

  } catch (error) {
    console.error('Erro ao excluir conta:', error)
    res.status(500).json({
      success: false,
      error: error.message || 'Erro ao excluir conta'
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

// Enviar mensagem de suporte
exports.sendSupportMessage = async (req, res) => {
  const { message } = req.body
  const userId = req.user.id

  try {
    if (!message || message.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Informe sua mensagem' })
    }

    const { data: userData, error: userError } = await supabase
      .from('manicures')
      .select('nome, email')
      .eq('id', userId)
      .single()

    if (userError || !userData) {
      return res.status(404).json({ success: false, error: 'Usuário não encontrado' })
    }

    const sent = await sendSupportEmail(userData.nome, userData.email, message.trim())

    if (!sent) {
      return res.status(500).json({ success: false, error: 'Erro ao enviar mensagem. Tente novamente.' })
    }

    res.json({ success: true, message: 'Mensagem enviada com sucesso!' })
  } catch (error) {
    console.error('Erro ao enviar suporte:', error)
    res.status(500).json({ success: false, error: 'Erro ao enviar mensagem' })
  }
}

// Esqueci minha senha - enviar e-mail de redefinição
exports.forgotPassword = async (req, res) => {
  const { email } = req.body

  try {
    if (!email || !email.includes('@')) {
      return res.status(400).json({ success: false, error: 'Informe um e-mail válido' })
    }

    const { data: existingUser } = await supabase.auth.admin.listUsers()
    const user = existingUser?.users?.find(u => u.email === email)

    if (!user) {
      return res.json({ success: true, message: 'Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha.' })
    }

    const nome = user.user_metadata?.nome || 'usuária'

    const resetToken = jwt.sign(
      { userId: user.id, email },
      JWT_SECRET,
      { expiresIn: '1h' }
    )

    const backendUrl = getBackendUrl(req)
    const frontendUrl = getFrontendUrl()
    const resetLink = `${backendUrl}/auth/reset-password?token=${resetToken}&redirect=${encodeURIComponent(frontendUrl + '/resetar-senha.html')}`

    const sent = await sendPasswordResetEmail(email, nome, resetLink)

    if (!sent) {
      return res.status(500).json({ success: false, error: 'Erro ao enviar e-mail. Tente novamente.' })
    }

    res.json({ success: true, message: 'Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha.' })
  } catch (error) {
    console.error('Erro ao enviar redefinição de senha:', error)
    res.status(500).json({ success: false, error: 'Erro ao processar solicitação' })
  }
}

// Redefinir senha - página (GET do link no e-mail)
exports.resetPasswordPage = async (req, res) => {
  const { token, redirect } = req.query
  const frontendUrl = getFrontendUrl()
  const redirectBase = redirect || `${frontendUrl}/resetar-senha.html`

  if (!token) {
    const separator = redirectBase.includes('?') ? '&' : '?'
    return res.redirect(`${redirectBase}${separator}status=invalid`)
  }

  // Verificar se o token é válido antes de redirecionar
  try {
    jwt.verify(token, JWT_SECRET)
    // Token válido — redirecionar para a página com o token na URL
    const separator = redirectBase.includes('?') ? '&' : '?'
    return res.redirect(`${redirectBase}${separator}token=${token}`)
  } catch (error) {
    const separator = redirectBase.includes('?') ? '&' : '?'
    if (error.name === 'TokenExpiredError') {
      return res.redirect(`${redirectBase}${separator}status=expired`)
    }
    return res.redirect(`${redirectBase}${separator}status=invalid`)
  }
}

// Redefinir senha - processar nova senha (POST)
exports.resetPassword = async (req, res) => {
  const { token } = req.query
  const { password } = req.body

  try {
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token não fornecido' })
    }

    if (!password || password.length < 6) {
      return res.status(400).json({ success: false, error: 'A senha deve ter pelo menos 6 caracteres' })
    }

    const decoded = jwt.verify(token, JWT_SECRET)

    const { error } = await supabase.auth.admin.updateUserById(decoded.userId, {
      password: password
    })

    if (error) throw error

    res.json({ success: true, message: 'Senha redefinida com sucesso!' })
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(400).json({ success: false, error: 'Link expirado. Solicite um novo link.' })
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(400).json({ success: false, error: 'Link inválido.' })
    }
    res.status(500).json({ success: false, error: 'Erro ao redefinir senha.' })
  }
}

