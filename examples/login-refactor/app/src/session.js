// Session tokens. The signing algorithm is decided by when the token was
// issued: tokens from before the cutoff still travel through the legacy
// HS256 window, everything at or after it is RS256.
const CUTOFF = Date.UTC(2026, 0, 1);
const WEEK = 7 * 24 * 60 * 60;

export function algorithmFor(issuedAt) {
  return issuedAt < CUTOFF ? "HS256" : "RS256";
}

export function createSession({ user, issuedAt, ttlSeconds }) {
  const iat = Math.floor(issuedAt / 1000);
  const alg = algorithmFor(issuedAt);
  return { sub: user.id, alg, iat, exp: iat + WEEK };
}
