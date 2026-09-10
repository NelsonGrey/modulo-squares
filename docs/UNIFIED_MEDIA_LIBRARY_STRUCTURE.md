# Media-library structure

Status: adopted for Modulo Squares

Date: 2026-09-04

## Decision

The Modulo Squares media library uses the publishing-first folder contract below.
The contract separates:

1. operating instructions and readiness;
2. reusable brand assets;
3. campaign master content;
4. platform-specific upload copies;
5. approved draft copy and calendars;
6. optional app-store listing media;
7. sources and editable production files;
8. inventory and provenance; and
9. material that must not be published.

The normal starting point is always `03-platform-ready/<platform>/`. Brand setup
starts in `01-brand/`. Copy selection starts in `04-copy/`. Everything beginning
with an underscore is production support or restricted material, not an upload
source.

Migration is copy-first: the build does not move or delete existing assets until
the new library validates and is approved.

## Current-state notes

The prior library was organized by publishing format, then platform. Its
strengths — clear upload-facing separation; strong video, post copy, calendar,
safeguard, provenance, and quarantine distinctions — are preserved. The main
friction it removed: brand assets and platform copies were split; `01-evergreen`
described lifespan rather than campaign/purpose; platform folders were uneven;
control documents were scattered across the root, `_inventory`, and `04-copy`.

| Concern | Was | Now |
|---|---|---|
| Brand | `00-brand` | `01-brand` |
| Campaigns | `01-evergreen` | `02-campaigns` |
| Upload source | `02-platform-ready` | `03-platform-ready` |
| Video | `03-video` | Campaign masters plus platform-ready video copies |
| Copy | `04-copy` | `04-copy` (fixed filenames) |
| Operator controls | Split between root, `_inventory`, and `04-copy` | `00-control` |
| Sources | External promo kit; recorded only in provenance | `_source` plus `SOURCE_MANIFEST.csv` |
| Inventory | `_inventory/library-manifest.csv` and `source-media.csv` | Fixed manifest names and schemas |
| Restricted material | Two explicit top-level folders | `_hold/review-evidence` and `_hold/quarantine` |

## Required target structure

```text
media-library/
├── README.md
├── 00-control/
│   ├── READINESS.md
│   ├── GAP_REGISTER.md
│   ├── OWNED_PROPERTIES.md
│   ├── PLATFORM_SPECS.md
│   └── PUBLISHING_CHECKLIST.md
├── 01-brand/
│   ├── masters/
│   ├── profiles/
│   ├── headers/
│   │   ├── facebook/
│   │   ├── reddit/
│   │   ├── x/
│   │   └── youtube/
│   ├── guidelines/
│   └── fonts/
├── 02-campaigns/
│   └── C001-campaign-slug/
│       ├── CAMPAIGN.md
│       ├── stills/
│       │   ├── square/
│       │   ├── portrait/
│       │   ├── landscape/
│       │   └── vertical/
│       ├── video/
│       │   ├── landscape/
│       │   └── vertical/
│       └── captions/
├── 03-platform-ready/
│   ├── facebook/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   ├── header/
│   │   ├── feed/
│   │   └── reels-stories/
│   ├── instagram/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   ├── feed/
│   │   └── reels-stories/
│   ├── reddit/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   ├── header/
│   │   ├── feed/
│   │   └── video/
│   ├── threads/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   ├── feed/
│   │   └── video/
│   ├── tiktok/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   └── video/
│   ├── x/
│   │   ├── INDEX.md
│   │   ├── profile/
│   │   ├── header/
│   │   ├── feed/
│   │   └── video/
│   └── youtube/
│       ├── INDEX.md
│       ├── profile/
│       ├── header/
│       ├── thumbnails/
│       ├── long-form/
│       └── shorts/
├── 04-copy/
│   ├── PROFILE_COPY.md
│   ├── POST_LIBRARY.md
│   ├── CONTENT_CALENDAR.md
│   ├── ALT_TEXT.csv
│   └── VIDEO_METADATA.md
├── 05-store-listings/
│   ├── apple/
│   │   ├── icon/
│   │   ├── screenshots/
│   │   └── previews/
│   └── google-play/
│       ├── icon/
│       ├── feature-graphic/
│       ├── screenshots/
│       └── previews/
├── _source/
│   ├── brand/
│   ├── captures/
│   │   ├── ios/
│   │   ├── android/
│   │   └── web/
│   ├── editable/
│   └── video/
├── _inventory/
│   ├── ASSET_MANIFEST.csv
│   ├── SOURCE_MANIFEST.csv
│   ├── PUBLISHING_INDEX.csv
│   ├── PROVENANCE.md
│   └── CHECKSUMS.sha256
└── _hold/
    ├── review-evidence/
    │   └── README.md
    └── quarantine/
        └── README.md
```

Every listed directory is part of the contract. A directory with no asset should
retain a short `README.md` explaining the gap instead of being silently omitted.
This makes absence explicit and keeps navigation identical.

## Folder contract

### `README.md`

The root README is a one-page operator guide, not a full audit. It must answer only:

- where to obtain an asset for each social property;
- where to find matching copy;
- what is currently safe to publish;
- which checks must occur immediately before publishing; and
- how to rebuild and validate the library.

### `00-control`

This folder holds five decision documents:

- `READINESS.md`: asset readiness by family and platform;
- `GAP_REGISTER.md`: missing, blocked, stale, or externally gated deliverables, each with an owner and next action;
- `OWNED_PROPERTIES.md`: official account name, handle, URL, purpose, and verification date;
- `PLATFORM_SPECS.md`: working export dimensions, safe-zone notes, and preview requirements;
- `PUBLISHING_CHECKLIST.md`: active-account, live-link, claim, rights, crop, alt-text, caption, and post-publication-log checks.

These documents describe current state. Historical audit narrative belongs in
project documentation or version control, not in the operator path.

### `01-brand`

This is the canonical visual-identity kit. `masters` contains the approved
highest-quality logo/mark sources. `profiles` and `headers` contain final
channel-setup assets, even when generated from a master. Headers are grouped by
platform because their crops differ. Fonts must include their license files.
Retired or alternate marks belong in `_hold/quarantine`, not beside the current
identity.

### `02-campaigns`

This is the canonical reusable content layer. Each campaign receives a stable ID
and a single folder. `CAMPAIGN.md` records:

- campaign ID, title, objective, audience, and product truth being communicated;
- approved claims and prohibited claims;
- CTA and live destination requirements;
- asset IDs included;
- matching copy IDs;
- lifecycle status and review date; and
- source/capture limitations.

The four still subfolders use meaning rather than a specific platform so one
master can feed several destinations. Videos retain caption sidecars in
`captions` and silent masters when platform audio will be added later.

### `03-platform-ready`

This is the only routine upload source. Every supported platform has a folder.
Each platform `INDEX.md` states:

- the current profile and header assets;
- which feed/video assets are ready, candidate, draft, held, or blocked;
- the exact copy IDs to pair with each asset;
- crop, safe-zone, caption, audio, link, and disclosure checks; and
- the last platform-preview verification date.

Files here are generated or copied from `01-brand` and `02-campaigns`; they are
not edited in place. Deliberate duplication is acceptable because this layer
optimizes publishing, while the manifest preserves a single source relationship.

### `04-copy`

Copy has fixed filenames. `POST_LIBRARY.md` assigns a stable copy ID to each
complete post. `ALT_TEXT.csv` maps asset IDs to alt text. `VIDEO_METADATA.md`
includes titles, descriptions, captions, disclosures, and destination-specific
notes. Draft status must remain explicit; inclusion in this folder is not
publication approval.

### `05-store-listings`

This folder is optional content but required structure. It prevents app-store
assets from being mixed with social feeds while keeping promotional
implementation material in one predictable library. Runtime application icons,
web favicons, and ordinary product runtime media do not belong here; only
listing/upload media does.

### `_source`

This folder contains production inputs, never routine upload selections. It may
hold canonical brand sources, native-resolution app/web captures, editable
layouts, audio/video masters, and generator inputs. Review-derived or defective
captures must go to `_hold/review-evidence`, not `_source`.

### `_inventory`

Inventory filenames and column definitions are fixed.

`ASSET_MANIFEST.csv` columns:

```text
asset_id,path,media_type,purpose,campaign_id,platform,width,height,duration_seconds,format,alpha,codec,pixel_format,audio,status,source_asset_id,version,reviewed_on,sha256
```

`SOURCE_MANIFEST.csv` columns:

```text
source_asset_id,source_path,source_type,classification,capture_context,rights,contains_personal_data,reviewed_on,notes,sha256
```

`PUBLISHING_INDEX.csv` columns:

```text
platform,placement,asset_id,copy_id,status,cta_url,preview_required,last_previewed_on,notes
```

Allowed status values are:

- `READY_LOCAL`: format/content checks passed; action-time account, link, and crop checks still apply;
- `NEEDS_PLATFORM_PREVIEW`: technically valid but native destination preview is outstanding;
- `DRAFT`: requires content approval or replacement input;
- `BLOCKED`: cannot be completed until a named dependency changes;
- `HOLD`: intentionally excluded from publishing;
- `RETIRED`: superseded and preserved only for traceability.

`PROVENANCE.md` records origins, generation/editing methods, model use when
applicable, licenses, capture devices/builds, and limitations.
`CHECKSUMS.sha256` covers all files the validator treats as managed assets.

### `_hold`

`review-evidence` is for QA captures, TestFlight/App Review media, flawed drafts,
and other evidence that must not be mistaken for marketing. `quarantine` is for
retired identity families, unsafe or sensitive material, and rejected creative.
The README in each folder explains why its contents are restricted.

## Standard naming

Use lowercase kebab case for media files:

```text
modulo-squares-{campaign-id}-{subject}-{placement}-{width}x{height}-{locale}-v{nn}.{ext}
```

Example:

```text
modulo-squares-c001-drop-numbers-feed-square-1080x1080-en-us-v01.png
```

Rules:

- use a stable `asset_id` in the manifest even if a filename changes;
- use `C000` for brand/setup material that is not a campaign;
- include dimensions for rendered visual media;
- include locale when words or narration are embedded;
- use two-digit versions only for meaningful creative revisions;
- never encode mutable readiness state in the filename; the manifest is authoritative;
- do not append `final`, `final-final`, `new`, `current`, or a date as a substitute for a version;
- capture dates and app/build versions belong in source metadata, not every delivery filename.

## Migration map

| Current | Target | Treatment |
|---|---|---|
| Root `README.md` | Root `README.md` | Rewrite against the operator template |
| `_inventory/ASSET_AUDIT.md` readiness/gaps | `00-control/READINESS.md` and `GAP_REGISTER.md` | Split current-state decisions from historical audit detail |
| `04-copy/OWNED_PROPERTIES.md` | `00-control/OWNED_PROPERTIES.md` | Copy |
| Format guidance in asset audit | `00-control/PLATFORM_SPECS.md` | Extract and normalize |
| `04-copy/PUBLISHING_CHECKLIST.md` | `00-control/PUBLISHING_CHECKLIST.md` | Copy |
| `00-brand` | `01-brand` | Preserve content; move headers into platform subfolders |
| `01-evergreen` | `02-campaigns` | Group numbered concepts under stable campaign IDs; treat key art as a brand or awareness campaign |
| `02-platform-ready` | `03-platform-ready` | Fill the full platform folder contract and add generated indexes |
| `03-video` | Matching campaign folders, then platform-ready copies | Keep the trailer/tutorial/short distinctions in metadata and placement folders |
| `04-copy` | `04-copy` | Rename files to the fixed contract; merge source-copy mapping into provenance/manifest metadata |
| Store promo kit references | `05-store-listings` or `SOURCE_MANIFEST.csv` | Copy only current upload assets; continue referencing the validated promo kit as source of truth |
| Empty quarantine/review folders | `_hold` | Preserve restrictions under the common names |

## Publishing workflow

1. Open `00-control/READINESS.md` and confirm the desired platform/placement is not blocked or held.
2. Open `03-platform-ready/<platform>/INDEX.md`.
3. Select the listed asset ID and matching copy ID.
4. Retrieve the complete draft from `04-copy/POST_LIBRARY.md` and alt text from `ALT_TEXT.csv`.
5. Complete `00-control/PUBLISHING_CHECKLIST.md`, including the active account, live link, claim, rights, and native crop/preview checks.
6. Publish manually unless a separately approved automation exists.
7. Record the published URL, date, asset ID, copy ID, and result in the publication log or campaign system.

## Build and validation contract

Two entry points:

```text
scripts/media-library/build-media-library.sh
scripts/media-library/validate-media-library.sh
```

The build must be deterministic, copy-first, and limited to managed targets
inside `media-library`. It must not delete unknown files or source assets.

The validator must fail when:

- a required contract directory or control document is missing;
- a manifest path does not exist;
- a managed asset is absent from `ASSET_MANIFEST.csv`;
- a platform-ready asset has `HOLD`, `BLOCKED`, or `RETIRED` status;
- a review-evidence/quarantine source is copied into a platform-ready directory;
- a checksum differs;
- an asset or copy ID is duplicated;
- a publishing-index row points to a missing asset or copy ID;
- a platform directory has neither usable content nor a documented gap; or
- operating-system residue is included in a managed manifest or checksum (the build removes Finder metadata, but validation tolerates macOS recreating it concurrently outside the managed inventory).

Validation success means local technical and organizational readiness, not
approval, public availability, account ownership, link health, rights clearance,
or native platform-preview success.

## Acceptance criteria

The migration is complete only when all of the following are true:

- the target tree and fixed control-document names exist;
- profile, header, post, short video, long video, thumbnail, and matching copy for any supported platform are reachable from the same paths, or a documented gap sits in that location;
- no raw capture, runtime tree, review evidence, retired mark, failed draft, or sensitive material appears in `03-platform-ready`;
- every managed output has an asset ID, source relationship, status, technical metadata, review date, and checksum;
- every platform-ready asset maps to a copy ID or explicitly states that no copy is required;
- every campaign documents claims, CTA conditions, limitations, and lifecycle status;
- builds are deterministic and copy-first;
- the validator passes;
- native preview requirements remain visibly separate from local validation;
- current storefront or product availability is never inferred from the presence of an asset; and
- the previous library remains recoverable until the owner approves cleanup.
