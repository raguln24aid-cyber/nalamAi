import { prisma } from '../../lib/prisma';
import { AppError, notFound } from '../../lib/errors';
import { z } from 'zod';
import { addAllergySchema, addRestrictionSchema, updateProfileSchema } from './schemas';

export async function getProfile(userId: string) {
  const [profile, allergies, restrictions] = await Promise.all([
    prisma.userProfile.upsert({
      where: { userId },
      update: {},
      create: { userId },
    }),
    prisma.allergy.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } }),
    prisma.dietaryRestriction.findMany({ where: { userId }, orderBy: { createdAt: 'asc' } }),
  ]);

  return {
    dietaryPreference: profile.dietaryPreference,
    notes: profile.notes,
    allergies,
    restrictions,
  };
}

export async function updateProfile(userId: string, input: z.infer<typeof updateProfileSchema>) {
  const profile = await prisma.userProfile.upsert({
    where: { userId },
    update: input,
    create: { userId, ...input },
  });
  return profile;
}

export async function addAllergy(userId: string, input: z.infer<typeof addAllergySchema>) {
  const existing = await prisma.allergy.findUnique({
    where: { userId_allergen: { userId, allergen: input.allergen.toLowerCase() } },
  });
  if (existing) {
    throw new AppError('CONFLICT', 'This allergy is already in your profile');
  }
  return prisma.allergy.create({
    data: { userId, allergen: input.allergen.toLowerCase(), severity: input.severity },
  });
}

export async function removeAllergy(userId: string, id: string) {
  const allergy = await prisma.allergy.findUnique({ where: { id } });
  if (!allergy || allergy.userId !== userId) throw notFound('Allergy');
  await prisma.allergy.delete({ where: { id } });
}

export async function addRestriction(userId: string, input: z.infer<typeof addRestrictionSchema>) {
  const existing = await prisma.dietaryRestriction.findUnique({
    where: { userId_restriction: { userId, restriction: input.restriction.toLowerCase() } },
  });
  if (existing) {
    throw new AppError('CONFLICT', 'This restriction is already in your profile');
  }
  return prisma.dietaryRestriction.create({
    data: { userId, restriction: input.restriction.toLowerCase() },
  });
}

export async function removeRestriction(userId: string, id: string) {
  const restriction = await prisma.dietaryRestriction.findUnique({ where: { id } });
  if (!restriction || restriction.userId !== userId) throw notFound('Dietary restriction');
  await prisma.dietaryRestriction.delete({ where: { id } });
}
