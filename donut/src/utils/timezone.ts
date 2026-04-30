// Get the UTC offset in hours for an IANA timezone string
export function getUtcOffsetHours(timezone: string): number {
  try {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      timeZoneName: "shortOffset",
    });
    const parts = formatter.formatToParts(now);
    const tzPart = parts.find((p) => p.type === "timeZoneName");
    if (!tzPart) return 0;

    const match = tzPart.value.match(/GMT([+-])(\d+)(?::(\d+))?/);
    if (!match) return 0;

    const sign = match[1] === "+" ? 1 : -1;
    const hours = parseInt(match[2], 10);
    const minutes = match[3] ? parseInt(match[3], 10) : 0;
    return sign * (hours + minutes / 60);
  } catch {
    return 0;
  }
}

// Check if two timezones are within a tolerance of each other (in hours)
export function timezonesOverlap(
  tz1: string,
  tz2: string,
  toleranceHours = 2,
): boolean {
  const offset1 = getUtcOffsetHours(tz1);
  const offset2 = getUtcOffsetHours(tz2);
  return Math.abs(offset1 - offset2) <= toleranceHours;
}

// Group timezone strings into buckets of similar offsets
export function bucketTimezones(
  timezones: string[],
  bucketSizeHours = 2,
): Map<number, string[]> {
  const buckets = new Map<number, string[]>();

  for (const tz of timezones) {
    const offset = getUtcOffsetHours(tz);
    const bucket = Math.round(offset / bucketSizeHours) * bucketSizeHours;
    const existing = buckets.get(bucket) ?? [];
    existing.push(tz);
    buckets.set(bucket, existing);
  }

  return buckets;
}
