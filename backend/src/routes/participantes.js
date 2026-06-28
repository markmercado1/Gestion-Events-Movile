const router = require('express').Router();
const { body } = require('express-validator');
const ctrl = require('../controllers/participantesController');
const auth = require('../middleware/auth');
const validar = require('../middleware/validar');
const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

router.use(auth);

router.get('/', ctrl.listar);

router.post('/', [
  body('evento_id').isInt({ min: 1 }).withMessage('ID de evento requerido'),
  body('nombre').notEmpty().trim().withMessage('El nombre es requerido'),
  body('client_uuid').optional().isUUID().withMessage('client_uuid invalido')
], validar, ctrl.crear);

router.post('/bulk', [
  body('evento_id').isInt({ min: 1 }).withMessage('ID de evento requerido'),
  body('participantes').isArray().withMessage('Debe ser un arreglo de participantes')
], validar, ctrl.crearLote);

router.post('/importar', upload.single('archivo'), ctrl.importarArchivo);

router.patch('/:id/asistencia', [
  body('base_updated_at').optional().isISO8601().withMessage('base_updated_at invalido')
], validar, ctrl.marcarAsistencia);

router.delete('/:id', ctrl.eliminar);

module.exports = router;
