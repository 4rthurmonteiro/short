import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

const code = 'aB3dE5g';
const url = 'https://example.com/path';

let testEnv;
let db;

const validLink = () => ({ url, createdAt: serverTimestamp() });

const seedLink = () =>
  testEnv.withSecurityRulesDisabled((context) =>
    setDoc(doc(context.firestore(), 'links', code), {
      url,
      createdAt: Timestamp.now(),
    }),
  );

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-short',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  db = testEnv.unauthenticatedContext().firestore();
});

after(() => testEnv.cleanup());

describe('read', () => {
  test('get is allowed', async () => {
    await seedLink();
    await assertSucceeds(getDoc(doc(db, 'links', code)));
  });

  test('get of a missing doc is allowed', async () => {
    await assertSucceeds(getDoc(doc(db, 'links', code)));
  });

  test('list is denied', async () => {
    await seedLink();
    await assertFails(getDocs(collection(db, 'links')));
  });
});

describe('create', () => {
  test('a valid link is allowed', async () => {
    await assertSucceeds(setDoc(doc(db, 'links', code), validLink()));
  });

  test('an http URL is allowed', async () => {
    await assertSucceeds(
      setDoc(doc(db, 'links', code), {
        url: 'http://example.com',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('a 2048-character URL is allowed', async () => {
    const longUrl = `https://example.com/${'a'.repeat(2048 - 20)}`;
    await assertSucceeds(
      setDoc(doc(db, 'links', code), { url: longUrl, createdAt: serverTimestamp() }),
    );
  });

  test('overwriting an existing code is denied', async () => {
    await seedLink();
    await assertFails(
      setDoc(doc(db, 'links', code), {
        url: 'https://evil.com',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('an extra field is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), { ...validLink(), extra: true }),
    );
  });

  test('a missing url is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), { createdAt: serverTimestamp() }),
    );
  });

  test('a missing createdAt is denied', async () => {
    await assertFails(setDoc(doc(db, 'links', code), { url }));
  });

  test('a non-string url is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), { url: 42, createdAt: serverTimestamp() }),
    );
  });

  test('a javascript: URL is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), {
        url: 'javascript:alert(1)',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('a URL with whitespace is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), {
        url: 'https://example.com/a b',
        createdAt: serverTimestamp(),
      }),
    );
  });

  test('a 2049-character URL is denied', async () => {
    const longUrl = `https://example.com/${'a'.repeat(2049 - 20)}`;
    await assertFails(
      setDoc(doc(db, 'links', code), { url: longUrl, createdAt: serverTimestamp() }),
    );
  });

  test('a client-set createdAt is denied', async () => {
    await assertFails(
      setDoc(doc(db, 'links', code), { url, createdAt: Timestamp.now() }),
    );
  });

  for (const badCode of ['short', 'toolong12', 'ab-cd_e', 'abc def']) {
    test(`code "${badCode}" is denied`, async () => {
      await assertFails(setDoc(doc(db, 'links', badCode), validLink()));
    });
  }
});

describe('update and delete', () => {
  test('update is denied', async () => {
    await seedLink();
    await assertFails(
      updateDoc(doc(db, 'links', code), { url: 'https://evil.com' }),
    );
  });

  test('delete is denied', async () => {
    await seedLink();
    await assertFails(deleteDoc(doc(db, 'links', code)));
  });
});
