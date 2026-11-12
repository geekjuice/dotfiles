---
user-invocable: true
description: "DRAFT — Draft a reply to a GitHub issue/PR comment, Slack thread, or support email, grounded in what this session already found. Never posts. Use for 'draft reply', 'draft a comment', 'how should I reply', or when Nick pastes his own version and says 'proofread' / 'how's this'. Flags: `--prose`, `--proofread`."
---

# reply

What you type by hand after a `--reply` pass or an investigation: "draft reply to <comment URL>
based on these findings", then "here's my version, proofread".

## 1. Target

- A comment URL: `gh api repos/<owner>/<repo>/issues/comments/<id>` (a review comment lives under
  `pulls/comments/<id>`) for the body and author, then the parent issue or PR body and its last
  five comments for context.
- A pasted thread (Slack, email): use as given.
- "the new comment" or no argument: the newest comment on the issue or PR this session's
  checkpoint names.

Quote the question being answered in one line: `Answering: <who> asked <what>`.

## 2. Ground it

- Pull the answer from this session's findings: `.ignore/investigations/<slug>.md`,
  `.ignore/reviews/<slug>.md`, the chat so far.
- Verify any claim the comment makes against code or data before agreeing with it. Nick: "don't
  blindly agree if it is actually needed."
- If the answer rests on inference, fan out first (learned/say-how-sure-unasked). One conclusion,
  not a pile of reports.
- The draft states as done only what Nick confirmed doing in this session. Anything pending is
  future tense or left out. Every name, number, and detail traces to the thread, the code, or
  Nick's words. A fact from your own investigation that the reader has no context for (an org
  list, a local UUID, the harness used) is cut, not explained.

## 3. Draft

Default: **Reply points (not posted):** 3-6 bullets: the answer in one clause, the cause, the
workaround or next step, any caveat. Bullets, not prose: Nick rewrites comments in his own voice.

`--prose`, or "prose" / "full" / "draft the full comment": 3 sentences, about 60 words. Sentence
one is the answer. Never restate the question or what the reader already knows. Read Nick's last
two comments on that thread first and match their openers and length. No headers, no bold labels,
no bullets. Zero em-dashes. @mention only the asker. "Shorter" means halve it.

Either way, end with the confidence line: the claims resting on inference and the one probe that
would settle them. Deliver paste-ready: a fenced block, no `>` prefix (learned/paste-ready).

## 4. Never post

No `gh issue comment`, no `gh pr comment`, no offer to post. Close with
`Waiting on you: post it` and the URL.

## 5. `--proofread`

Auto when the prompt starts with "here's my version", "how's this", "hows this", "finish this",
or "proofread".

- Return Nick's text with only errors fixed: facts, typos, broken links, wrong names. Same length,
  same wording otherwise. Never shorten or rewrite unasked.
- Then `Suggested additions:` as bullets he can paste in, one line each.
- Then one line per change you made.
