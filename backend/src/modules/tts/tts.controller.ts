import { Router } from 'express';
import { asyncHandler } from '../../middleware/asyncHandler';
import { authGuard } from '../../middleware/authGuard';
import { validateBody } from '../../middleware/validate';
import { getTtsProvider } from '../../providers';
import { TtsProviderError } from '../../providers/tts.provider';
import { AppError } from '../../lib/errors';
import { synthesizeSchema } from './schemas';

export const ttsRouter = Router();
ttsRouter.use(authGuard);

ttsRouter.post(
  '/synthesize',
  validateBody(synthesizeSchema),
  asyncHandler(async (req, res) => {
    const provider = getTtsProvider();
    try {
      const audio = await provider.synthesize(req.body.text, req.body.language);
      res.setHeader('Content-Type', 'audio/mpeg');
      res.send(audio);
    } catch (err) {
      if (err instanceof TtsProviderError) {
        throw new AppError('PROVIDER_UNAVAILABLE', 'TTS service is temporarily unavailable');
      }
      throw err;
    }
  }),
);
