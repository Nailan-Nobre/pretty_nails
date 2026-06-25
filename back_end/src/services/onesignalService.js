const https = require('https');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY;

async function sendPushNotification(playerIds, title, body, data = {}) {
  if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_API_KEY) {
    console.log('[OneSignal] App ID ou REST API Key não configurados, pulando push');
    return;
  }

  if (!playerIds || playerIds.length === 0) {
    console.log('[OneSignal] Nenhum player ID fornecido');
    return;
  }

  const validIds = playerIds.filter(id => id && id.trim().length > 0);
  if (validIds.length === 0) {
    console.log('[OneSignal] Nenhum player ID válido após filtro');
    return;
  }

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
            console.error('[OneSignal] Erros na resposta:', result.errors);
          } else if (result.id) {
            console.log(`[OneSignal] Push enviada com sucesso. ID: ${result.id}, recipients: ${result.recipients || 'N/A'}`);
          } else {
            console.log('[OneSignal] Resposta:', body);
          }
          resolve(result);
        } catch (e) {
          console.log('[OneSignal] Resposta não-JSON:', body);
          resolve(body);
        }
      });
    });

    req.on('error', (error) => {
      console.error('[OneSignal] Erro de conexão:', error.message);
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
    .select('onesignal_player_id')
    .eq('id', manicureId)
    .single();

  if (error || !manicure) {
    console.error('Erro ao buscar manicure para push:', error);
    return;
  }

  const playerId = manicure.onesignal_player_id;
  if (!playerId) {
    console.log(`Manicure ${manicureId} sem player ID registrado`);
    return;
  }

  try {
    await sendPushNotification([playerId], title, body, data);
    console.log(`Push enviado para manicure ${manicureId}`);
  } catch (err) {
    console.error(`Falha ao enviar push para manicure ${manicureId}:`, err.message || err);
  }
}

module.exports = {
  sendPushNotification,
  sendPushToManicure,
};
