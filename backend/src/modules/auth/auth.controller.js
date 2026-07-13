import {
  InvalidCredentialsError,
  InvalidRefreshTokenError,
  login,
  refreshTokens,
} from './auth.service.js';

/**
 * POST /api/auth/login
 * Body: { matricule, password }
 */
export async function loginController(req, res, next) {
  try {
    const { matricule, password } = req.body ?? {};
    if (!matricule || !password) {
      return res
        .status(400)
        .json({ error: 'matricule and password are required' });
    }

    const result = await login({ matricule, password });
    return res.status(200).json(result);
  } catch (err) {
    if (err instanceof InvalidCredentialsError) {
      return res.status(401).json({ error: err.message });
    }
    return next(err);
  }
}

/**
 * POST /api/auth/refresh
 * Body: { refreshToken }  ->  { accessToken, refreshToken }
 */
export async function refreshController(req, res, next) {
  try {
    const { refreshToken } = req.body ?? {};
    if (!refreshToken) {
      return res.status(400).json({ error: 'refreshToken is required' });
    }
    const tokens = await refreshTokens(refreshToken);
    return res.status(200).json(tokens);
  } catch (err) {
    if (err instanceof InvalidRefreshTokenError) {
      return res.status(401).json({ error: err.message });
    }
    return next(err);
  }
}
