# Development note seed

This seed is intentionally kept out of production app code. Use it only in the
Firebase console for project `tugether-a3dea` while signed in as the tutor who
owns the target class.

## 1. Find the class and tutor IDs

Open Firestore Data, select `classes/{classId}`, and copy:

- the class document ID as `CLASS_ID`
- the `tutorId` field as `TUTOR_UID`

## 2. Create the note document

Create `classes/CLASS_ID/notes/dictionary-week-05` with these fields:

| Field | Type | Value |
| --- | --- | --- |
| `classId` | string | `CLASS_ID` |
| `title` | string | `Dictionary` |
| `summary` | string | `Dictionary의 기본 구조와 활용 방법` |
| `week` | number | `5` |
| `authorId` | string | `TUTOR_UID` |
| `status` | string | `published` |
| `createdAt` | timestamp | current time |
| `updatedAt` | timestamp | current time |
| `publishedAt` | timestamp | current time |

Use `draft` instead of `published` to verify that tutees cannot see the note.

## 3. Create ordered blocks

Under the note, create a `blocks` subcollection and these documents:

### `heading-01`

```text
noteId: "dictionary-week-05" (string)
type: "heading" (string)
order: 1 (number)
content: "Dictionary" (string)
language: null (null)
```

### `paragraph-02`

```text
noteId: "dictionary-week-05" (string)
type: "paragraph" (string)
order: 2 (number)
content: "Dictionary는 key-value 형태로 데이터를 저장합니다. key를 사용하면 원하는 값을 빠르게 찾고 수정할 수 있습니다." (string)
language: null (null)
```

### `code-03`

```text
noteId: "dictionary-week-05" (string)
type: "code" (string)
order: 3 (number)
content: "scores = {\n  \"Alice\": 95,\n  \"Bob\": 88\n}\nprint(scores[\"Alice\"])" (string)
language: "python" (string)
```

### `quiz-04`

```text
noteId: "dictionary-week-05" (string)
type: "quiz" (string)
order: 4 (number)
content: "Quick Check placeholder" (string)
language: null (null)
```

The app listens to these documents in real time. Refresh is not required after
the documents are created. The Quick Check block is display-only in this phase.
