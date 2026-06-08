 grep -n "export async function" store.js |grep -i session
207:export async function startSession(routineId) {
220:export async function completeSession(sessionId, completedExerciseIds = []) {
231:export async function getSessionsForRoutine(routineId) {
237:export async function getLastCompletedSession(routineId) {
521:export async function createSession({ routineId, routineTitle, totalExercises, totalSets }) {
543:export async function updateSession(id, updates) {
555:export async function deleteSession(id) {
563:export async function getAllSessions() {
572:export async function getSession(id) {
581:export async function getSessionsByStatus(status) {
589:export async function getSessionsByRoutine(routineId) {
