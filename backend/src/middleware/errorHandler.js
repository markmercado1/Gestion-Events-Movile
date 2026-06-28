module.exports = (err, req, res, next) => {
  console.error('❌ Error:', err.message);
  if (err.code === 'ER_DUP_ENTRY')
    return res.status(409).json({ error: 'El recurso ya existe (valor duplicado)' });
  if (err.code === 'ER_NO_REFERENCED_ROW_2')
    return res.status(400).json({ error: 'Referencia invalida (ID no existe)' });
  res.status(err.status || 500).json({ error: err.message || 'Error interno del servidor' });
};
