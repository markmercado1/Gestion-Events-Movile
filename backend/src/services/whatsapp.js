/**
 * Envía un mensaje de WhatsApp a través de Callmebot si está configurado en .env
 */
async function enviarWhatsApp({ nombre, telefono, tipo_evento, fecha_evento, sede_preferida, mensaje }) {
  const phone = process.env.WHATSAPP_PHONE;
  const apiKey = process.env.WHATSAPP_API_KEY;

  if (!phone || !apiKey) {
    console.log('ℹ️ WhatsApp no configurado en .env. Llena WHATSAPP_PHONE y WHATSAPP_API_KEY para activar alertas por WhatsApp.');
    return;
  }

  const fecha = fecha_evento ? new Date(fecha_evento).toLocaleDateString('es-PE', { day: '2-digit', month: 'long', year: 'numeric' }) : 'No especificada';

  const text = `🔔 *Nueva Cotización* 🎊\n\n` +
               `👤 *Nombre:* ${nombre}\n` +
               `📱 *Teléfono:* ${telefono}\n` +
               `🎉 *Evento:* ${tipo_evento || 'No especificado'}\n` +
               `📅 *Fecha:* ${fecha}\n` +
               `📍 *Sede:* ${sede_preferida || 'Sin preferencia'}\n` +
               (mensaje ? `💬 *Mensaje:* ${mensaje}\n` : '') +
               `\n👉 _Event Juliaca_`;

  const url = `https://api.callmebot.com/whatsapp.php?phone=${encodeURIComponent(phone)}&text=${encodeURIComponent(text)}&apikey=${encodeURIComponent(apiKey)}`;

  try {
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`HTTP error! status: ${res.status}`);
    }
    console.log('🤖 Alerta de WhatsApp enviada exitosamente.');
  } catch (error) {
    console.error('⚠️ Error enviando alerta de WhatsApp:', error.message);
  }
}

module.exports = { enviarWhatsApp };
