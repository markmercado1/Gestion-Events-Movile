const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/**
 * Envía un email de notificación cuando llega una nueva cotización
 */
async function notificarCotizacion({ nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje }) {
  const fecha = fecha_evento ? new Date(fecha_evento).toLocaleDateString('es-PE', { day: '2-digit', month: 'long', year: 'numeric' }) : 'No especificada';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f0f; color: #e0e0e0; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 30px auto; background: #1a1a1a; border-radius: 16px; overflow: hidden; border: 1px solid #2a2a2a; }
        .header { background: linear-gradient(135deg, #f59e0b, #d97706); padding: 30px; text-align: center; }
        .header h1 { margin: 0; color: #fff; font-size: 24px; letter-spacing: 1px; }
        .header p { margin: 8px 0 0; color: rgba(255,255,255,0.85); font-size: 14px; }
        .body { padding: 30px; }
        .badge { display: inline-block; background: rgba(245,158,11,0.15); border: 1px solid rgba(245,158,11,0.3); color: #f59e0b; padding: 4px 14px; border-radius: 999px; font-size: 12px; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 20px; }
        .row { margin-bottom: 16px; }
        .label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-bottom: 4px; }
        .value { font-size: 15px; color: #f0f0f0; background: #252525; padding: 10px 14px; border-radius: 8px; border-left: 3px solid #f59e0b; }
        .mensaje-box { background: #252525; border-radius: 10px; padding: 16px; color: #ccc; font-size: 14px; line-height: 1.6; border-left: 3px solid #f59e0b; }
        .footer { padding: 20px 30px; border-top: 1px solid #2a2a2a; text-align: center; color: #555; font-size: 12px; }
        .btn { display: inline-block; margin-top: 20px; background: #f59e0b; color: #000; padding: 12px 28px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 14px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎉 Nueva Solicitud de Cotización</h1>
          <p>Event Juliaca — Sistema de Gestión</p>
        </div>
        <div class="body">
          <span class="badge">📋 Nueva cotización recibida</span>

          <div class="row">
            <div class="label">👤 Nombre del cliente</div>
            <div class="value">${nombre}</div>
          </div>

          <div class="row">
            <div class="label">📱 Teléfono / WhatsApp</div>
            <div class="value">${telefono}</div>
          </div>

          <div class="row">
            <div class="label">🎊 Tipo de evento</div>
            <div class="value">${tipo_evento || 'No especificado'}</div>
          </div>

          <div class="row">
            <div class="label">📅 Fecha del evento</div>
            <div class="value">${fecha}</div>
          </div>

          <div class="row">
            <div class="label">📍 Sede preferida</div>
            <div class="value">${sede_preferida || 'Sin preferencia'}</div>
          </div>

          ${mensaje ? `
          <div class="row">
            <div class="label">💬 Mensaje</div>
            <div class="mensaje-box">${mensaje}</div>
          </div>
          ` : ''}

          <div style="text-align:center">
            <a href="http://localhost:5173" class="btn">Ver en el Sistema →</a>
          </div>
        </div>
        <div class="footer">
          Este correo fue generado automáticamente por Event Juliaca.<br>
          ${new Date().toLocaleString('es-PE', { timeZone: 'America/Lima' })} — Hora de Perú
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from: `"Event Juliaca 🎊" <${process.env.EMAIL_USER}>`,
    to: process.env.EMAIL_DEST,
    subject: `🔔 Nueva cotización de ${nombre} — ${tipo_evento || 'Evento'}`,
    html,
  });
}

/**
 * Envía email de confirmación de registro al participante
 */
async function confirmarRegistroParticipante({ nombre, email, eventoNombre, fechaEvento, horaInicio, horaFin, sede }) {
  const fecha = fechaEvento ? new Date(fechaEvento).toLocaleDateString('es-PE', { day: '2-digit', month: 'long', year: 'numeric' }) : 'Por confirmar';

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f0f; color: #e0e0e0; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 30px auto; background: #1a1a1a; border-radius: 16px; overflow: hidden; border: 1px solid #2a2a2a; }
        .header { background: linear-gradient(135deg, #f59e0b, #d97706); padding: 30px; text-align: center; }
        .header h1 { margin: 0; color: #fff; font-size: 24px; letter-spacing: 1px; }
        .header p { margin: 8px 0 0; color: rgba(255,255,255,0.85); font-size: 14px; }
        .body { padding: 30px; }
        .badge { display: inline-block; background: rgba(245,158,11,0.15); border: 1px solid rgba(245,158,11,0.3); color: #f59e0b; padding: 4px 14px; border-radius: 999px; font-size: 12px; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 20px; }
        .row { margin-bottom: 16px; }
        .label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-bottom: 4px; }
        .value { font-size: 15px; color: #f0f0f0; background: #252525; padding: 10px 14px; border-radius: 8px; border-left: 3px solid #f59e0b; }
        .footer { padding: 20px 30px; border-top: 1px solid #2a2a2a; text-align: center; color: #555; font-size: 12px; }
        .btn { display: inline-block; margin-top: 20px; background: #f59e0b; color: #000; padding: 12px 28px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 14px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>✅ Registro Confirmado</h1>
          <p>Event Juliaca — Tu lugar está reservado</p>
        </div>
        <div class="body">
          <span class="badge">🎟️ Confirmación de asistencia</span>

          <div class="row">
            <div class="label">👤 Nombre del participante</div>
            <div class="value">${nombre}</div>
          </div>

          <div class="row">
            <div class="label">🎉 Evento</div>
            <div class="value">${eventoNombre}</div>
          </div>

          <div class="row">
            <div class="label">📅 Fecha</div>
            <div class="value">${fecha}</div>
          </div>

          <div class="row">
            <div class="label">🕐 Horario</div>
            <div class="value">${horaInicio} — ${horaFin}</div>
          </div>

          ${sede ? `
          <div class="row">
            <div class="label">📍 Sede</div>
            <div class="value">${sede}</div>
          </div>
          ` : ''}

          <div style="text-align:center">
            <a href="http://localhost:5173" class="btn">Ver más detalles →</a>
          </div>
        </div>
        <div class="footer">
          Este correo fue generado automáticamente por Event Juliaca.<br>
          ${new Date().toLocaleString('es-PE', { timeZone: 'America/Lima' })} — Hora de Perú
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from: `"Event Juliaca 🎊" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: `✅ Confirmación de registro — ${eventoNombre}`,
    html,
  });
}

/**
 * Notifica al admin cuando una IP acumula demasiados intentos fallidos de login
 */
async function notificarIntentosFallidos({ ip, fecha, intentos }) {
  const fechaStr = fecha instanceof Date
    ? fecha.toLocaleString('es-PE', { timeZone: 'America/Lima' })
    : String(fecha);

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; background: #0f0f0f; color: #e0e0e0; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 30px auto; background: #1a1a1a; border-radius: 16px; overflow: hidden; border: 1px solid #2a2a2a; }
        .header { background: linear-gradient(135deg, #dc2626, #b91c1c); padding: 30px; text-align: center; }
        .header h1 { margin: 0; color: #fff; font-size: 24px; letter-spacing: 1px; }
        .header p { margin: 8px 0 0; color: rgba(255,255,255,0.85); font-size: 14px; }
        .body { padding: 30px; }
        .alert-box { background: rgba(220,38,38,0.1); border: 1px solid rgba(220,38,38,0.3); border-radius: 10px; padding: 16px 20px; margin-bottom: 24px; color: #fca5a5; font-size: 14px; line-height: 1.6; }
        .row { margin-bottom: 16px; }
        .label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #888; margin-bottom: 4px; }
        .value { font-size: 15px; color: #f0f0f0; background: #252525; padding: 10px 14px; border-radius: 8px; border-left: 3px solid #dc2626; }
        .footer { padding: 20px 30px; border-top: 1px solid #2a2a2a; text-align: center; color: #555; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>⚠️ Alerta de Seguridad</h1>
          <p>Event Juliaca — Intentos de acceso sospechosos</p>
        </div>
        <div class="body">
          <div class="alert-box">
            Se detectaron <strong>${intentos} intentos fallidos</strong> de inicio de sesión desde la misma IP en los últimos 15 minutos.
          </div>
          <div class="row">
            <div class="label">🌐 Dirección IP</div>
            <div class="value">${ip}</div>
          </div>
          <div class="row">
            <div class="label">🕐 Fecha y hora</div>
            <div class="value">${fechaStr} — Hora de Perú</div>
          </div>
          <div class="row">
            <div class="label">🔢 Intentos fallidos</div>
            <div class="value">${intentos}</div>
          </div>
        </div>
        <div class="footer">
          Este correo fue generado automáticamente por Event Juliaca.<br>
          Si no reconoces esta actividad, revisa los accesos al sistema.
        </div>
      </div>
    </body>
    </html>
  `;

  await transporter.sendMail({
    from: `"Event Juliaca 🎊" <${process.env.EMAIL_USER}>`,
    to: process.env.EMAIL_DEST,
    subject: `⚠️ Alerta: ${intentos} intentos fallidos de login desde ${ip}`,
    html,
  });
}

module.exports = { notificarCotizacion, confirmarRegistroParticipante, notificarIntentosFallidos };
