const router = require('express').Router();
const ctrl = require('../controllers/usuariosController');
const { soloAdmin } = require('../middleware/auth');
const auth = require('../middleware/auth');
const auditoria = require('../middleware/auditoria');
router.get('/me', auth, ctrl.me);
router.get('/', auth, soloAdmin, ctrl.listar);
router.put('/:id/rol', auth, soloAdmin, auditoria('usuarios'), ctrl.actualizarRol);
module.exports = router;
