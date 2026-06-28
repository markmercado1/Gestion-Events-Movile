const router = require('express').Router();
const { body } = require('express-validator');
const ctrl = require('../controllers/cotizacionesController');
const auth = require('../middleware/auth');
const validar = require('../middleware/validar');

const reglas = [
  body('nombre').notEmpty().trim().withMessage('El nombre es requerido'),
  body('telefono').notEmpty().trim().withMessage('El teléfono es requerido'),
  body('client_uuid').optional().isUUID().withMessage('client_uuid invalido')
];

// Ruta pública para crear la cotización
router.post('/', reglas, validar, ctrl.crear);

// Rutas protegidas para administración
router.use(auth);
router.get('/', ctrl.listar);
router.put('/:id/estado', [
  body('estado').isIn(['pendiente', 'contactado', 'descartado']).withMessage('Estado inválido'),
  body('base_updated_at').optional().isISO8601().withMessage('base_updated_at invalido')
], validar, ctrl.actualizarEstado);

module.exports = router;
