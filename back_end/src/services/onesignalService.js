const https = require('https');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY;

async function sendPushNotification(playerIds, title, body, data = {}) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.log('OneSignal não configurado, pulando push notification');
    return;
  }

  if (!playerIds || playerIds.length === 0) {
    console.log('Nenhum player ID para enviar notificação');
    return;
  }

  const validIds = playerIds.filter(id => id && id.trim().length > 0);
  if (validIds.length === 0) return;

  const payload = JSON.stringify({
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: validIds,
    headings: { en: title },
    contents: { en: body },
    data: data,
    android_accent_color: 'FF6B6B',
    small_icon: 'launcher_icon',
    large_icon: 'launcher_icon',
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'onesignal.com',
      port: 443,
      path: '/api/v1/notifications',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
        'Content-Length': Buffer.byteLength(payload),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          const result = JSON.parse(body);
          if (result.errors) {
            console.error('OneSignal errors:', result.errors);
          } else {
            console.log('Push notification enviada:', result.id);
          }
          resolve(result);
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', (error) => {
      console.error('Erro ao enviar push notification:', error);
      reject(error);
    });

    req.write(payload);
    req.end();
  });
}

async function sendPushToManicure(manicureId, title, body, data = {}) {
  const supabase = require('../config/db');

  const { data: manicure, error } = await supabase
    .from('manicures')
    .select('onesignal_player_id, notificacoes_email')
    .eq('id', manicureId)
    .single();

  if (error || !manicure) {
    console.error('Erro ao buscar manicure para push:', error);
    return;
  }

  if (manicure.notificacoes_email === false) {
    console.log('Manicure desativou notificações');
    return;
  }

  const playerId = manicure.onesignal_player_id;
  if (!playerId) {
    console.log('Manicure sem player ID registrado');
    return;
  }

  await sendPushNotification([playerId], title, body, data);
}

module.exports = {
  sendPushNotification,
  sendPushToManicure,
};
