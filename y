import { openDB } from 'idb';
import { generateId } from '../utils/id.js';
import { createSeedActivities, createSampleRoutine } from './seed.js';

const DB_NAME = 'phasely';
const DB_VERSION = 2;

const STORE_ROUTINES = 'routines';
const STORE_ACTIVITIES = 'activities';
const STORE_SESSIONS = 'sessions';
const STORE_META = 'meta';

let dbPromise = null;

function getDB() {
  if (!dbPromise) {
    dbPromise = openDB(DB_NAME, DB_VERSION, {
      upgrade(db, oldVersion) {
        // v1: initial schema
        if (oldVersion < 1) {
          const routinesStore = db.createObjectStore(STORE_ROUTINES, {
            keyPath: 'id',
          });
          routinesStore.createIndex('order', 'order');
          routinesStore.createIndex('updatedAt', 'updatedAt');

          const sessionsStore = db.createObjectStore(STORE_SESSIONS, {
            keyPath: 'id',
          });
          sessionsStore.createIndex('routineId', 'routineId');
          sessionsStore.createIndex('startedAt', 'startedAt');

          db.createObjectStore(STORE_META, { keyPath: 'key' });
        }
        
        // v2: add activities store
        if (oldVersion < 2) {
          const activitiesStore = db.createObjectStore(STORE_ACTIVITIES, {
            keyPath: 'id',
          });
          activitiesStore.createIndex('name', 'name');
          activitiesStore.createIndex('updatedAt', 'updatedAt');
        }
      },
    });
  }
  return dbPromise;
}
