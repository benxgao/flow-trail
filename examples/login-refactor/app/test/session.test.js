import test from "node:test";
import assert from "node:assert/strict";
import { algorithmFor, createSession } from "../src/session.js";

const DAY = 24 * 60 * 60 * 1000;
const CUTOFF = Date.UTC(2026, 0, 1);

test("a token issued a day before the cutoff stays HS256", () => {
  assert.equal(algorithmFor(CUTOFF - DAY), "HS256");
});

test("a token issued a day after the cutoff is RS256", () => {
  assert.equal(algorithmFor(CUTOFF + DAY), "RS256");
});

test("the cutoff itself is the switch, not the secret", () => {
  assert.equal(algorithmFor(CUTOFF), "RS256");
});

test("a session carries the seven-day default expiry", () => {
  const s = createSession({ user: { id: "u1" }, issuedAt: CUTOFF + DAY });
  assert.equal(s.exp - s.iat, 7 * 24 * 60 * 60);
});

test("a caller-supplied ttl wins over the default", () => {
  const s = createSession({ user: { id: "u1" }, issuedAt: CUTOFF + DAY, ttlSeconds: 3600 });
  assert.equal(s.exp - s.iat, 3600);
});
