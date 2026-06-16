$ cat src/views/player.js |head -30
/**
 * Centerline — Session Player (Workout Runner)
 * 
 * Full-screen view that guides user through a workout routine.
 * Step 2.3: Connected to SessionEngine for live timer + phase transitions.
 * 
 * Route: #/play/:routineId
 */

import {
  getRoutine,
  getMeta, setMeta,
  createSession, updateSession, deleteSession,
  findResumableSession,
} from '../db/store.js';
import { router } from '../utils/router.js';
import { confirmModal, alertModal } from '../components/dialog.js';
import { SessionEngine } from '../core/sessionEngine.js';
import { CueManager } from '../core/cueManager.js';
import { acquireWakeLock, releaseWakeLock } from '../utils/wakeLock.js';
import { openModal, closeModal } from '../components/modal.js';

// Module-level reference to the active engine (for cleanup on navigation away)
let activeEngine = null;
let activeCues = null;
let activeContainer = null;
let activeSession = null;
let activeRoutine = null;
let visibilityHandler = null;
let pauseReason = null;

$ grep -n "export async function renderPlayer" src/views/player.js 
33:export async function renderPlayer(container, routineId) {

$  grep -n "addEventListener" src/views/routineDetail.js |head -20
38:    container.querySelector('#back-btn').addEventListener('click', () => router.navigate('/'));
94:  container.querySelector('#back-btn').addEventListener('click', () => router.navigate('/'));
95:  container.querySelector('#edit-btn').addEventListener('click', () => {
99:  container.querySelector('#start-btn').addEventListener('click', async () => {
110:  container.querySelector('#history-btn').addEventListener('click', () => {
114:  container.querySelector('#delete-btn').addEventListener('click', async () => {

$ cat src/views/routineDetail.js |sed -n '145,180p'

function renderExerciseList(exercises) {
  return `
    <section class="exercise-detail-list">
      <h3 class="section-heading">Exercises</h3>
      ${exercises.map((ex, i) => renderExerciseItem(ex, i + 1)).join('')}
    </section>
  `;
}

function renderExerciseItem(exercise, position) {
  const video = parseVideoUrl(exercise.videoUrl);
  const videoLink = video
    ? `<a href="${escapeHtml(video.originalUrl)}" target="_blank" rel="noopener noreferrer" class="video-link">▶ Watch demonstration</a>`
    : '';

  const restNote = exercise.sets > 1 && exercise.restBetweenSets > 0
    ? ` · ${exercise.restBetweenSets}s rest`
    : '';

  return `
    <article class="exercise-detail-item">
      <div class="exercise-position">${position}</div>
      <div class="exercise-detail-main">
        <h4 class="exercise-detail-name">${escapeHtml(exercise.name)}</h4>
        ${exercise.description ? `<p class="exercise-detail-desc">${escapeHtml(exercise.description)}</p>` : ''}
        <p class="exercise-detail-meta">
          ${exercise.workDuration}s hold × ${exercise.sets} set${exercise.sets === 1 ? '' : 's'}${restNote}
        </p>
        ${videoLink}
      </div>
    </article>
  `;
}

function escapeHtml(str) {

