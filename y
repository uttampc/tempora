$ grep -A 20 "export async function updateSession" db/store.js 
export async function updateSession(id, updates) {
  const db = await getDB();
  const existing = await db.get(STORE_SESSIONS, id);
  if (!existing) throw new Error(`Session ${id} not found`);
  const merged = { ...existing, ...updates };
  await db.put(STORE_SESSIONS, merged);
  return merged;
}

/**
 * Deletes a session (used when user discards an incomplete workout).
 */
export async function deleteSession(id) {
  const db = await getDB();
  await db.delete(STORE_SESSIONS, id);
}

/**
 * Returns all sessions, sorted by startedAt descending (newest first).
 */
export async function getAllSessions() {

$ grep -A 20 "export async function createSession" db/store.js 
export async function createSession({ routineId, routineTitle, totalExercises, totalSets }) {
  const db = await getDB();
  const session = {
    id: generateId(),
    routineId,
    routineTitle,
    startedAt: Date.now(),
    completedAt: null,
    status: 'in-progress',
    totalElapsed: 0,
    exercisesCompleted: 0,
    totalExercises,
    setsCompleted: 0,
    totalSets,
  };
  await db.put(STORE_SESSIONS, session);
  return session;
}
