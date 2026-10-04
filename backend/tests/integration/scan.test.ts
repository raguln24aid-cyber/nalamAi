/** Integration test — requires a real Postgres instance, see auth.test.ts header comment. */
import request from 'supertest';
import { createApp } from '../../src/app';
import { prisma } from '../../src/lib/prisma';

const app = createApp();

async function registerAndLogin(email: string) {
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({ email, password: 'correct-horse-battery-staple' });
  return res.body.accessToken as string;
}

describe('Scan -> safety -> assistant flow (integration, mock providers)', () => {
  const email = `scan-test-${Date.now()}@nalamai.test`;
  let token: string;

  beforeAll(async () => {
    token = await registerAndLogin(email);
  });

  afterAll(async () => {
    const user = await prisma.user.findUnique({ where: { email } });
    if (user) await prisma.user.delete({ where: { id: user.id } });
    await prisma.$disconnect();
  });

  it('adds a peanut allergy to the profile', async () => {
    const res = await request(app)
      .post('/api/v1/profile/allergies')
      .set('Authorization', `Bearer ${token}`)
      .send({ allergen: 'peanuts', severity: 'severe' });
    expect(res.status).toBe(201);
  });

  let scanId: string;

  it('processes a scan from a mock image and raises a critical allergen safety flag', async () => {
    const res = await request(app)
      .post('/api/v1/scans')
      .set('Authorization', `Bearer ${token}`)
      .send({ imageBase64: Buffer.from('fake-jpeg-bytes').toString('base64'), languageHint: 'en' });

    expect(res.status).toBe(202);
    expect(res.body.status).toBe('completed');
    expect(res.body.product.name).toBeTruthy();
    expect(res.body.product.allergens.length).toBeGreaterThan(0);

    const criticalFlag = res.body.safetyFlags.find((f: { type: string }) => f.type === 'allergen_match');
    expect(criticalFlag).toBeTruthy();
    expect(criticalFlag.severity).toBe('critical');
    scanId = res.body.scanId;
  });

  it('answers an AI assistant question using only the extracted product data', async () => {
    const res = await request(app)
      .post('/api/v1/assistant/query')
      .set('Authorization', `Bearer ${token}`)
      .send({ scanId, question: 'What is the sugar content?', language: 'en' });

    expect(res.status).toBe(200);
    expect(res.body.answer).toBeTruthy();
    expect(res.body.language).toBe('en');
  });

  it('rejects a request for a scan owned by another user', async () => {
    const otherToken = await registerAndLogin(`scan-test-other-${Date.now()}@nalamai.test`);
    const res = await request(app)
      .get(`/api/v1/scans/${scanId}`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.status).toBe(404);
  });
});
