const router = require('express').Router();
const ctrl = require('../controllers/auditoriaController');
const auth = require('../middleware/auth');
const { soloAdmin } = require('../middleware/auth');
router.use(auth, soloAdmin);
router.get('/', ctrl.listar);
module.exports = router;
