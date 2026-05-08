#!/usr/bin/env bash
# task1 — Print + log the organizer email body.
# This is a coordinator-only task; produces a tiny report so it slots into
# the same status pipeline as the compute tasks.
set -euo pipefail

TASK_ID="task1"
TASK_NAME="Print organizer email body for copy-paste"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

EMAIL_SRC="$TBXT_ROOT/organizer_questions.md"
if [ ! -f "$EMAIL_SRC" ]; then
    log_error "$EMAIL_SRC not found"
    _end FAIL; exit 1
fi

OUT_TXT="$DATA_DIR/email_body.txt"
cp "$EMAIL_SRC" "$OUT_TXT"
log_info "Email body copied to: $OUT_TXT"
log_info ""
log_info "═══════════════════════ EMAIL BODY ═══════════════════════"
cat "$OUT_TXT"
log_info "═════════════════════ END EMAIL BODY ═════════════════════"
log_info ""
log_info "Send to: tbxtchallenge@chordoma.org"
log_info "Subject: Pre-event questions for the TBXT Hit-Identification Hackathon (May 9, Pillar VC)"

# Build extras JSON for the report
EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$OUT_TXT" "$EMAIL_SRC" <<'PYEOF'
import json, sys, hashlib, os
out, body_path, src_path = sys.argv[1:]
body = open(body_path).read()
n_questions = body.count("\n**") + body.count("\n###")  # rough heuristic
data = {
    "email_source": src_path,
    "email_body_path": body_path,
    "email_body_chars": len(body),
    "email_body_sha256": hashlib.sha256(body.encode()).hexdigest()[:16],
    "n_question_markers": n_questions,
    "recipient": "tbxtchallenge@chordoma.org",
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
