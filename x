$ grep -rn "startSession\|completeSession\|getSessionsForRoutine\|getLastCompletedSession" src/
src/db/store.js:207:export async function startSession(routineId) {
src/db/store.js:220:export async function completeSession(sessionId, completedExerciseIds = []) {
src/db/store.js:231:export async function getSessionsForRoutine(routineId) {
src/db/store.js:237:export async function getLastCompletedSession(routineId) {
src/db/store.js:238:  const sessions = await getSessionsForRoutine(routineId);
src/views/routineList.js:1:import { getAllRoutines, getLastCompletedSession } from '../db/store.js';
src/views/routineList.js:12:      const last = await getLastCompletedSession(r.id);
