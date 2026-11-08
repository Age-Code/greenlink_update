// Firestore security rules tests. Run against the emulator:
//   cd firestore_rules_test && npm install && npm run test:emulator
// Covers the user-owned collections (classMemberships, quizAttempts, reviews)
// and class members, as listed in ARCHITECTURE.md.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  Timestamp,
  where,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-studytogether';
const TUTOR = 'tutor-1';
const TUTEE = 'tutee-1';
const OTHER_TUTEE = 'tutee-2';
const STRANGER = 'stranger-1';
const CLASS_ID = 'class-1';
const QUIZ_ID = 'quiz-1';
const DRAFT_QUIZ_ID = 'quiz-draft';
const QUESTION_ID = 'question-1';
const REVIEW_ID = `${CLASS_ID}_${QUIZ_ID}_${QUESTION_ID}`;

let testEnv;

const emulatorHost = () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080')
    .split(':');
  return { host, port: Number(port) };
};

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      ...emulatorHost(),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'classes', CLASS_ID), {
      title: '파이썬 기초 스터디',
      tutorId: TUTOR,
      tutorName: '김튜터',
      inviteCode: 'ABCD1234',
      memberCount: 2,
      noteCount: 0,
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'classes', CLASS_ID, 'members', TUTOR), member(TUTOR, 'tutor'));
    await setDoc(doc(db, 'classes', CLASS_ID, 'members', TUTEE), member(TUTEE, 'tutee'));
    await setDoc(doc(db, 'classes', CLASS_ID, 'quizzes', QUIZ_ID), {
      classId: CLASS_ID,
      createdBy: TUTOR,
      title: '딕셔너리 퀴즈',
      status: 'published',
    });
    await setDoc(doc(db, 'classes', CLASS_ID, 'quizzes', DRAFT_QUIZ_ID), {
      classId: CLASS_ID,
      createdBy: TUTOR,
      title: '초안 퀴즈',
      status: 'draft',
    });
  });
});

const as = (uid) => testEnv.authenticatedContext(uid).firestore();
const anonymous = () => testEnv.unauthenticatedContext().firestore();
const seed = (write) => testEnv.withSecurityRulesDisabled((context) => write(context.firestore()));

function member(uid, role, name = '이름') {
  return { uid, role, name, joinedAt: Timestamp.now() };
}

function membership(overrides = {}) {
  return {
    classId: CLASS_ID,
    role: 'tutee',
    title: '파이썬 기초 스터디',
    joinedAt: Timestamp.now(),
    ...overrides,
  };
}

function answer(questionId, isCorrect) {
  return { questionId, selectedAnswer: isCorrect ? 1 : 0, isCorrect, answeredAt: Timestamp.now() };
}

function attempt(overrides = {}) {
  return {
    id: 'attempt-1',
    userId: TUTEE,
    classId: CLASS_ID,
    quizId: QUIZ_ID,
    noteId: null,
    startedAt: Timestamp.now(),
    completedAt: Timestamp.now(),
    totalQuestions: 2,
    correctCount: 1,
    answers: [answer('q1', true), answer('q2', false)],
    ...overrides,
  };
}

function review(overrides = {}) {
  return {
    userId: TUTEE,
    classId: CLASS_ID,
    quizId: QUIZ_ID,
    questionId: QUESTION_ID,
    noteId: 'note-1',
    blockId: null,
    topic: 'Dictionary',
    prompt: '존재하지 않는 key 조회하기',
    lastSelectedOptionIndex: 0,
    status: 'needsReview',
    wrongCount: 1,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    ...overrides,
  };
}

describe('users/{uid}/classMemberships', () => {
  const ref = (db, uid = TUTEE, classId = CLASS_ID) =>
    doc(db, 'users', uid, 'classMemberships', classId);

  test('the owner records a membership of an existing class', async () => {
    await assertSucceeds(setDoc(ref(as(TUTEE)), membership()));
  });

  test('the document id must be the classId', async () => {
    await assertFails(setDoc(ref(as(TUTEE), TUTEE, 'other-class'), membership()));
  });

  test('role must be tutor or tutee', async () => {
    await assertFails(setDoc(ref(as(TUTEE)), membership({ role: 'admin' })));
  });

  test('a membership of a class that does not exist is rejected', async () => {
    await assertFails(setDoc(ref(as(TUTEE), TUTEE, 'ghost'), membership({ classId: 'ghost' })));
  });

  test('only the owner reads or writes their memberships', async () => {
    await seed((db) => setDoc(ref(db), membership()));
    await assertSucceeds(getDoc(ref(as(TUTEE))));
    await assertFails(getDoc(ref(as(TUTOR))));
    await assertFails(getDoc(ref(as(STRANGER))));
    await assertFails(setDoc(ref(as(STRANGER)), membership()));
    await assertSucceeds(deleteDoc(ref(as(TUTEE))));
  });
});

describe('classes/{classId}/members', () => {
  const ref = (db, uid) => doc(db, 'classes', CLASS_ID, 'members', uid);

  test('any signed-in user can read the member list, anonymous cannot', async () => {
    await assertSucceeds(getDoc(ref(as(STRANGER), TUTEE)));
    await assertFails(getDoc(ref(anonymous(), TUTEE)));
  });

  test('a user joins by writing their own member document', async () => {
    await assertSucceeds(setDoc(ref(as(OTHER_TUTEE), OTHER_TUTEE), member(OTHER_TUTEE, 'tutee', '박학생')));
  });

  test('nobody can add someone else as a member', async () => {
    await assertFails(setDoc(ref(as(TUTEE), STRANGER), member(STRANGER, 'tutee')));
    await assertFails(setDoc(ref(as(TUTOR), STRANGER), member(STRANGER, 'tutee')));
  });

  test('the uid field, role and name are validated', async () => {
    await assertFails(setDoc(ref(as(OTHER_TUTEE), OTHER_TUTEE), member(TUTEE, 'tutee')));
    await assertFails(setDoc(ref(as(OTHER_TUTEE), OTHER_TUTEE), member(OTHER_TUTEE, 'admin')));
    await assertFails(setDoc(ref(as(OTHER_TUTEE), OTHER_TUTEE), { ...member(OTHER_TUTEE, 'tutee'), name: 42 }));
  });

  test('the class tutor or the member themself may remove a member', async () => {
    await assertFails(deleteDoc(ref(as(STRANGER), TUTEE)));
    await assertFails(deleteDoc(ref(as(OTHER_TUTEE), TUTEE)));
    await assertSucceeds(deleteDoc(ref(as(TUTOR), TUTEE)));
    await seed((db) => setDoc(ref(db, TUTEE), member(TUTEE, 'tutee')));
    await assertSucceeds(deleteDoc(ref(as(TUTEE), TUTEE)));
  });
});

describe('users/{uid}/quizAttempts', () => {
  const ref = (db, uid = TUTEE, attemptId = 'attempt-1') =>
    doc(db, 'users', uid, 'quizAttempts', attemptId);

  test('a class member stores an attempt on a published quiz', async () => {
    await assertSucceeds(setDoc(ref(as(TUTEE)), attempt()));
  });

  test('a non-member cannot store an attempt for the class', async () => {
    await assertFails(setDoc(ref(as(STRANGER), STRANGER), attempt({ userId: STRANGER })));
  });

  test('attempts on a draft quiz are rejected', async () => {
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ quizId: DRAFT_QUIZ_ID })));
  });

  test('scores and answer counts must be consistent', async () => {
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ correctCount: 3 })));
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ answers: [answer('q1', true)] })));
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ totalQuestions: 0, answers: [] })));
  });

  test('the stored id must match the document id and owner', async () => {
    await assertFails(setDoc(ref(as(TUTEE), TUTEE, 'attempt-2'), attempt()));
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ userId: OTHER_TUTEE })));
  });

  test('attempts cannot be edited; only the owner may delete them (account deletion)', async () => {
    await seed((db) => setDoc(ref(db), attempt()));
    await assertFails(setDoc(ref(as(TUTEE)), attempt({ correctCount: 2 })));
    await assertFails(deleteDoc(ref(as(TUTOR))));
    await assertFails(deleteDoc(ref(as(STRANGER))));
    await assertSucceeds(deleteDoc(ref(as(TUTEE))));
  });

  test('the owner and the class tutor can read, others cannot', async () => {
    await seed((db) => setDoc(ref(db), attempt()));
    await assertSucceeds(getDoc(ref(as(TUTEE))));
    await assertSucceeds(getDoc(ref(as(TUTOR))));
    await assertFails(getDoc(ref(as(OTHER_TUTEE))));
    await assertFails(getDoc(ref(as(STRANGER))));
  });

  test('the tutor dashboard collection-group query works only for the class tutor', async () => {
    await seed((db) => setDoc(ref(db), attempt()));
    const byClass = (db) =>
      getDocs(query(collectionGroup(db, 'quizAttempts'), where('classId', '==', CLASS_ID)));
    await assertSucceeds(byClass(as(TUTOR)));
    await assertFails(byClass(as(TUTEE)));
    await assertFails(byClass(as(STRANGER)));
  });
});

describe('users/{uid}/reviews', () => {
  const ref = (db, uid = TUTEE, reviewId = REVIEW_ID) =>
    doc(db, 'users', uid, 'reviews', reviewId);

  test('a class member records a first wrong answer', async () => {
    await assertSucceeds(setDoc(ref(as(TUTEE)), review()));
  });

  test('the document id must be classId_quizId_questionId', async () => {
    await assertFails(setDoc(ref(as(TUTEE), TUTEE, 'random-id'), review()));
  });

  test('a new item starts at wrongCount 1 with a valid status', async () => {
    await assertFails(setDoc(ref(as(TUTEE)), review({ wrongCount: 2 })));
    await assertFails(setDoc(ref(as(TUTEE)), review({ wrongCount: 0 })));
    await assertFails(setDoc(ref(as(TUTEE)), review({ status: 'done' })));
  });

  test('a non-member or a mismatched owner cannot create one', async () => {
    await assertFails(setDoc(ref(as(STRANGER), STRANGER), review({ userId: STRANGER })));
    await assertFails(setDoc(ref(as(TUTEE)), review({ userId: OTHER_TUTEE })));
  });

  test('repeat misses only ever raise wrongCount; marking reviewed keeps it', async () => {
    await seed((db) => setDoc(ref(db), review()));
    await assertSucceeds(setDoc(ref(as(TUTEE)), review({ wrongCount: 2 })));
    await assertFails(setDoc(ref(as(TUTEE)), review({ wrongCount: 1 })));
    await assertSucceeds(setDoc(ref(as(TUTEE)), review({ wrongCount: 2, status: 'reviewed' })));
  });

  test('an item cannot be re-pointed at another question', async () => {
    await seed((db) => setDoc(ref(db), review()));
    await assertFails(setDoc(ref(as(TUTEE)), review({ questionId: 'question-2' })));
    await assertFails(setDoc(ref(as(TUTEE)), review({ quizId: DRAFT_QUIZ_ID })));
  });

  test('reviews stay private to the learner; tutors cannot read them', async () => {
    await seed((db) => setDoc(ref(db), review()));
    await assertSucceeds(getDoc(ref(as(TUTEE))));
    await assertFails(getDoc(ref(as(TUTOR))));
    await assertFails(getDoc(ref(as(STRANGER))));
    await assertSucceeds(deleteDoc(ref(as(TUTEE))));
  });
});

describe('users/{uid} profile', () => {
  const ref = (db, uid = TUTEE) => doc(db, 'users', uid);
  const profile = { email: 'tutee@example.com', name: '이튜티', role: 'tutee', createdAt: Timestamp.now() };

  test('only the owner deletes their profile', async () => {
    await seed((db) => setDoc(ref(db), profile));
    await assertFails(deleteDoc(ref(as(STRANGER))));
    await assertFails(deleteDoc(ref(as(TUTOR))));
    await assertSucceeds(deleteDoc(ref(as(TUTEE))));
  });
});

describe('classes/{classId} memberCount', () => {
  const ref = (db) => doc(db, 'classes', CLASS_ID);
  const withCount = (memberCount) => ({ memberCount, updatedAt: Timestamp.now() });
  const update = (db, memberCount) =>
    setDoc(ref(db), withCount(memberCount), { merge: true });

  test('a joining user raises the count by one', async () => {
    await assertSucceeds(update(as(OTHER_TUTEE), 3));
  });

  test('a current member lowers the count by one while leaving', async () => {
    await assertSucceeds(update(as(TUTEE), 1));
  });

  test('others cannot lower it, and no one may jump by more than one', async () => {
    await assertFails(update(as(STRANGER), 1));
    await assertFails(update(as(TUTEE), 0));
    await assertFails(update(as(OTHER_TUTEE), 4));
  });
});

describe('classes/{classId}/notifications', () => {
  const ref = (db, id = 'n-1') => doc(db, 'classes', CLASS_ID, 'notifications', id);
  const notification = (overrides = {}) => ({
    classId: CLASS_ID,
    type: 'notePublished',
    title: '새 노트가 게시됐어요',
    body: 'Dictionary',
    actorId: TUTOR,
    actorName: '김튜터',
    targetId: 'note-1',
    createdAt: Timestamp.now(),
    ...overrides,
  });

  test('the tutor announces a published note or quiz', async () => {
    await assertSucceeds(setDoc(ref(as(TUTOR)), notification()));
    await assertSucceeds(setDoc(ref(as(TUTOR), 'n-2'), notification({ type: 'quizPublished', targetId: 'quiz-1' })));
  });

  test('a student cannot announce publishes, but can announce their own join', async () => {
    await assertFails(setDoc(ref(as(TUTEE)), notification({ actorId: TUTEE })));
    await assertSucceeds(setDoc(ref(as(TUTEE)), notification({ type: 'memberJoined', actorId: TUTEE, actorName: '이튜티', targetId: TUTEE })));
  });

  test('actorId must be the writer and non-members cannot write', async () => {
    await assertFails(setDoc(ref(as(TUTOR)), notification({ actorId: TUTEE })));
    await assertFails(setDoc(ref(as(STRANGER)), notification({ type: 'memberJoined', actorId: STRANGER })));
  });

  test('members read, strangers cannot, and nothing is edited afterwards', async () => {
    await seed((db) => setDoc(ref(db), notification()));
    await assertSucceeds(getDoc(ref(as(TUTEE))));
    await assertSucceeds(getDoc(ref(as(TUTOR))));
    await assertFails(getDoc(ref(as(STRANGER))));
    await assertFails(setDoc(ref(as(TUTOR)), notification({ title: '수정' })));
    await assertFails(deleteDoc(ref(as(TUTEE))));
    await assertSucceeds(deleteDoc(ref(as(TUTOR))));
  });
});
