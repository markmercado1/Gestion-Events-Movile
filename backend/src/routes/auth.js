const router=require('express').Router();
const {body}=require('express-validator');
const ctrl=require('../controllers/authController');
const validar=require('../middleware/validar');
const rateLimit=require('express-rate-limit');
const auth=require('../middleware/auth');

const loginLimiter=rateLimit({
  windowMs: 15*60*1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Demasiados intentos de inicio de sesión. Intenta de nuevo en 15 minutos.' }
});

const reglas=[body('email').isEmail().normalizeEmail().withMessage('Email invalido'),body('password').isLength({min:6}).withMessage('Password minimo 6 caracteres')];
router.post('/registro',reglas,validar,ctrl.registro);
router.post('/login',loginLimiter,reglas,validar,ctrl.login);
router.post('/refresh',auth,ctrl.refreshToken);
module.exports=router;
