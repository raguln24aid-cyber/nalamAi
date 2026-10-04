/**
 * Integration tests hit a real Postgres instance via Prisma. Requires:
 *   docker-compose up -d
 *   DATABASE_URL=postgresql://nalamai:nalamai@localhost:5432/nalamai_test?schema=public \
 *     npx prisma migrate deploy
 * before running `npm test`. See backend/README.md.
 */
import request from 'supertest';
import { createApp } from '../../src/app';
import { prisma } from '../../src/lib/prisma';

const app = createApp();

async function cleanupUser(email: string) {
  const user = await prisma.user.findUnique({ where: { email } });
  if (user) {
    await prisma.user.delete({ where: { id: user.id } });
  }
}

describe('Auth flow (integration)', () => {
  const email = `test-${Date.now()}@nalamai.test`;
  const password = 'correct-horse-battery-staple';

  afterAll(async () => {
    await cleanupUser(email);
    await prisma.$disconnect();
  });

  it('registers a new user and returns a token pair', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ email, password });
    expect(res.status).toBe(201);
    expect(res.body.user.email).toBe(email);
    expect(res.body.accessToken).toBeTruthy();
    expect(res.body.refreshToken).toBeTruthy();
  });

  it('rejects a duplicate registration', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({ email, password });
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  it('logs in with correct credentials', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({ email, password });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeTruthy();
  });

  it('rejects an incorrect password with the same error as a nonexistent user', async () => {
    const wrongPassword = await request(app).post('/api/v1/auth/login').send({ email, password: 'wrong' });
    const noSuchUser = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'nobody@nalamai.test', password: 'wrong' });

    expect(wrongPassword.status).toBe(401);
    expect(noSuchUser.status).toBe(401);
    expect(wrongPassword.body.error.message).toBe(noSuchUser.body.error.message);
  });

  it('rejects an unauthenticated request to a protected route', async () => {
    const res = await request(app).get('/api/v1/profile');
    expect(res.status).toBe(401);
  });

  it('allows profile access with a valid access token', async () => {
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    const res = await request(app)
      .get('/api/v1/profile')
      .set('Authorization', `Bearer ${login.body.accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.dietaryPreference).toBe('none');
  });

  it('rotates refresh tokens and rejects reuse of the old one', async () => {
    const login = await request(app).post('/api/v1/auth/login').send({ email, password });
    const refreshed = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });
    expect(refreshed.status).toBe(200);

    const reused = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });
    expect(reused.status).toBe(401);
  });
});
