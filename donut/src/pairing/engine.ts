import { getRecentPairings } from "./history";

type PairKey = `${string}:${string}`;

function makePairKey(a: string, b: string): PairKey {
  return a < b ? `${a}:${b}` : `${b}:${a}`;
}

type Member = {
  userId: string;
  timezone: string | null;
};

type PairingOptions = {
  channelConfigId: number;
  members: Member[];
  groupSize: number;
  cooldownRounds: number;
  timezoneMode: boolean;
};

// Compute a weight for pairing two users based on history.
// Higher weight = more desirable to pair.
// Returns 0 if within cooldown (forbidden).
function pairWeight(
  a: string,
  b: string,
  history: Map<PairKey, number>,
  cooldownRounds: number,
): number {
  const key = makePairKey(a, b);
  const roundsAgo = history.get(key);

  if (roundsAgo === undefined) return 100; // never paired = max weight
  if (roundsAgo <= cooldownRounds) return 0; // within cooldown = forbidden
  return roundsAgo * 10; // older pairings get higher weight
}

// Weighted random pick from an array with weights
function weightedPick<T>(items: T[], weights: number[]): number {
  const total = weights.reduce((sum, w) => sum + w, 0);
  if (total === 0) return Math.floor(Math.random() * items.length); // fallback to uniform

  let r = Math.random() * total;
  for (let i = 0; i < weights.length; i++) {
    r -= weights[i];
    if (r <= 0) return i;
  }
  return items.length - 1;
}

// Fisher-Yates shuffle
function shuffle<T>(arr: T[]): T[] {
  const result = [...arr];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

// Group members by timezone bucket (±2hr tolerance)
function groupByTimezone(members: Member[]): Member[][] {
  const buckets = new Map<number, Member[]>();

  for (const member of members) {
    const offset = getUtcOffsetHours(member.timezone ?? "UTC");
    // Round to nearest 2-hour bucket
    const bucket = Math.round(offset / 2) * 2;
    const existing = buckets.get(bucket) ?? [];
    existing.push(member);
    buckets.set(bucket, existing);
  }

  // Sort buckets by offset
  const sorted = [...buckets.entries()].sort((a, b) => a[0] - b[0]);
  return sorted.map(([, members]) => members);
}

function getUtcOffsetHours(timezone: string): number {
  try {
    const now = new Date();
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      timeZoneName: "shortOffset",
    });
    const parts = formatter.formatToParts(now);
    const tzPart = parts.find((p) => p.type === "timeZoneName");
    if (!tzPart) return 0;

    // Format is like "GMT+5" or "GMT-8" or "GMT+5:30"
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

// Core pairing algorithm
// Returns groups of user IDs
export async function generatePairings(options: PairingOptions): Promise<string[][]> {
  const { channelConfigId, members, groupSize, cooldownRounds, timezoneMode } = options;

  if (members.length < 2) return [];
  if (members.length <= groupSize) return [members.map((m) => m.userId)];

  const history = await getRecentPairings(channelConfigId, cooldownRounds);

  let memberPool: Member[];
  if (timezoneMode) {
    // Group by timezone, then flatten — this keeps tz-similar people adjacent
    // so the greedy group-forming picks them together
    const tzGroups = groupByTimezone(members);
    memberPool = tzGroups.flatMap((group) => shuffle(group));
  } else {
    memberPool = shuffle(members);
  }

  const groups: string[][] = [];
  const assigned = new Set<string>();

  // Greedily form groups
  while (assigned.size < memberPool.length) {
    const remaining = memberPool.filter((m) => !assigned.has(m.userId));
    if (remaining.length === 0) break;

    // If remaining < groupSize, distribute into existing groups
    if (remaining.length < groupSize && groups.length > 0) {
      for (const member of remaining) {
        // Find the group where this member has the best average weight
        let bestGroupIdx = 0;
        let bestWeight = -1;

        for (let g = 0; g < groups.length; g++) {
          const avgWeight =
            groups[g].reduce((sum, uid) => sum + pairWeight(member.userId, uid, history, cooldownRounds), 0) /
            groups[g].length;
          if (avgWeight > bestWeight) {
            bestWeight = avgWeight;
            bestGroupIdx = g;
          }
        }

        groups[bestGroupIdx].push(member.userId);
        assigned.add(member.userId);
      }
      break;
    }

    // Start a new group with the first unassigned member
    const seed = remaining[0];
    const group: string[] = [seed.userId];
    assigned.add(seed.userId);

    // Greedily add members with highest weight to current group
    while (group.length < groupSize) {
      const candidates = memberPool.filter((m) => !assigned.has(m.userId));
      if (candidates.length === 0) break;

      const weights = candidates.map((candidate) => {
        // Average weight across all current group members
        const total = group.reduce(
          (sum, uid) => sum + pairWeight(candidate.userId, uid, history, cooldownRounds),
          0,
        );
        return total / group.length;
      });

      const pickedIdx = weightedPick(candidates, weights);
      const picked = candidates[pickedIdx];
      group.push(picked.userId);
      assigned.add(picked.userId);
    }

    groups.push(group);
  }

  return groups;
}
