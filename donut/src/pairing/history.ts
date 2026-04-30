import { eq, desc } from "drizzle-orm";
import { db } from "../db/client";
import { rounds, pairings, pairingMembers } from "../db/schema";

type PairKey = `${string}:${string}`;

function makePairKey(a: string, b: string): PairKey {
  return a < b ? `${a}:${b}` : `${b}:${a}`;
}

// Returns a map of pair keys to how many rounds ago they were last paired.
// Only looks back `cooldownRounds` rounds for the given channel config.
export async function getRecentPairings(
  channelConfigId: number,
  cooldownRounds: number,
): Promise<Map<PairKey, number>> {
  const recentRounds = await db
    .select({ id: rounds.id })
    .from(rounds)
    .where(eq(rounds.channelConfigId, channelConfigId))
    .orderBy(desc(rounds.executedAt))
    .limit(cooldownRounds);

  if (recentRounds.length === 0) return new Map();

  const roundIds = recentRounds.map((r) => r.id);
  const pairHistory = new Map<PairKey, number>();

  for (let i = 0; i < roundIds.length; i++) {
    const roundId = roundIds[i];
    const roundsAgo = i + 1;

    // Get all pairings in this round
    const groups = await db
      .select({ pairingId: pairings.id })
      .from(pairings)
      .where(eq(pairings.roundId, roundId));

    for (const group of groups) {
      // Get members in this pairing group
      const groupMembers = await db
        .select({ userId: pairingMembers.userId })
        .from(pairingMembers)
        .where(eq(pairingMembers.pairingId, group.pairingId));

      const userIds = groupMembers.map((m) => m.userId);

      // Generate all pairs within this group
      for (let a = 0; a < userIds.length; a++) {
        for (let b = a + 1; b < userIds.length; b++) {
          const key = makePairKey(userIds[a], userIds[b]);
          // Keep the most recent (smallest roundsAgo) occurrence
          if (!pairHistory.has(key)) {
            pairHistory.set(key, roundsAgo);
          }
        }
      }
    }
  }

  return pairHistory;
}

// Record a completed round and its pairing groups
export async function recordRound(
  channelConfigId: number,
  groups: string[][],
): Promise<number> {
  const [round] = await db
    .insert(rounds)
    .values({
      channelConfigId,
      executedAt: new Date(),
      groupCount: groups.length,
    })
    .returning({ id: rounds.id });

  for (let i = 0; i < groups.length; i++) {
    const [pairing] = await db
      .insert(pairings)
      .values({
        roundId: round.id,
        groupIndex: i,
      })
      .returning({ id: pairings.id });

    const memberRows = groups[i].map((userId) => ({
      pairingId: pairing.id,
      userId,
    }));

    await db.insert(pairingMembers).values(memberRows);
  }

  return round.id;
}
