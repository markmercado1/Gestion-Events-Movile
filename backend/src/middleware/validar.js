const { validationResult } = require('express-validator');
module.exports = (req, res, next) => {
  const errores = validationResult(req);
  if (!errores.isEmpty()) return res.status(422).json({ errores: errores.array() });
  next();
};
