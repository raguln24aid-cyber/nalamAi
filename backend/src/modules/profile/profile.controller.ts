import { Router } from 'express';
import { asyncHandler } from '../../middleware/asyncHandler';
import { authGuard } from '../../middleware/authGuard';
import { validateBody } from '../../middleware/validate';
import { addAllergySchema, addRestrictionSchema, updateProfileSchema } from './schemas';
import * as profileService from './profile.service';

export const profileRouter = Router();
profileRouter.use(authGuard);

profileRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const profile = await profileService.getProfile(req.user!.userId);
    res.json(profile);
  }),
);

profileRouter.put(
  '/',
  validateBody(updateProfileSchema),
  asyncHandler(async (req, res) => {
    const profile = await profileService.updateProfile(req.user!.userId, req.body);
    res.json(profile);
  }),
);

profileRouter.post(
  '/allergies',
  validateBody(addAllergySchema),
  asyncHandler(async (req, res) => {
    const allergy = await profileService.addAllergy(req.user!.userId, req.body);
    res.status(201).json(allergy);
  }),
);

profileRouter.delete(
  '/allergies/:id',
  asyncHandler(async (req, res) => {
    await profileService.removeAllergy(req.user!.userId, req.params.id!);
    res.status(204).send();
  }),
);

profileRouter.post(
  '/restrictions',
  validateBody(addRestrictionSchema),
  asyncHandler(async (req, res) => {
    const restriction = await profileService.addRestriction(req.user!.userId, req.body);
    res.status(201).json(restriction);
  }),
);

profileRouter.delete(
  '/restrictions/:id',
  asyncHandler(async (req, res) => {
    await profileService.removeRestriction(req.user!.userId, req.params.id!);
    res.status(204).send();
  }),
);
