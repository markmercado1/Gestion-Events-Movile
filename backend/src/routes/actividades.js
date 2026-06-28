const router = require('express').Router();
const ctrl = require('../controllers/actividadesController');
const auth = require('../middleware/auth');
router.get('/evento/:evento_id/ical', ctrl.generarIcal);
router.get('/', ctrl.listar);
router.post('/', auth, ctrl.crear);
router.put('/:id', auth, ctrl.actualizar);
router.delete('/:id', auth, ctrl.eliminar);
module.exports = router;
