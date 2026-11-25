---
kind: explanation
status: proposed
owner: founder
last_reviewed: 2026-11-25
---

# Principles of a self-adapting work system

> Proposed. The autonomy rule (section 9), the artifact states and the protocol (section 10)
> are recorded in
> [ADR-013](../decisions/adrs/adr-013-skill-lifecycle-and-autonomy-ceiling.md). Written to be
> general: it applies to any system where agents (human or AI) do work guided by editable
> instructions, not only to coding skills.

## 0. How to read the Sanskrit

The Vedic sources are used as **lenses, not authority**. Each concept is paraphrased from the
tradition, then turned into an engineering rule, then tied to something that can be checked.
A principle with no check is marked *judgement*: it is a rubric a reviewer applies, not a gate.

Citations are chapter.verse for the Bhagavad Gita (Gita), Patanjali's Yoga Sutras (YS), and by
name for the Upanishads. The Gita and YS belong to the wider Vedic/Vedantic tradition (smriti
and darshana), not to the Vedas proper (shruti). Verify any phrase against a translation
before quoting it; the schools disagree on several of these, and this document picks one
reading and says so.

## 1. The one idea

**Keep the principles fixed and let the practices change.**

The tradition separates what is eternal (*sanatana dharma*: truthfulness, non-harm, restraint)
from what depends on place, time and person (*desha-kala-patra*: the rule that fits this
context). A skill, a rule, a prompt and a hook are practices. They may be created, rewritten
and retired by the loop below. The principles are not. They change only by a human decision
recorded in an ADR.

This is what makes the system self-adaptable without becoming self-corrupting: adaptation is
allowed at the layer where it is safe, and forbidden at the layer where it is not.

## 2. The attributes of work

The Gita (18.14) names five factors in any action: the **seat** (*adhishthana*), the **doer**
(*karta*), the **instruments** (*karana*), the **efforts** (*cheshta*) and **the unseen**
(*daiva*). Verse 18.18 adds that the whole of an action is instrument, act and doer. That
gives a complete, non-coding-specific list of what a work system has to account for.

| Attribute | Vedic anchor | Principle | Where it lives (chassis / agnova) |
|---|---|---|---|
| **Seat**: what the work stands on | *adhishthana* (Gita 18.14) | The substrate is part of the work. Reproducible, versioned, inspectable, or the work is not. | Git, devcontainer, `justfile`, pinned tools. Agent home repos in agnova. |
| **Doer**: who acts | *karta*, *svadharma* (Gita 3.35) | Each actor has a role with its own duty. A role does its own work, not another's, even if it could. | Per-harness config; agent persona and `PRINCIPLES.md` in agnova homes. |
| **Instruments**: what is used | *karana* (Gita 18.14) | Instruments are chosen for the task and are distinct from the doer. Skills, tools and hooks are instruments, not identity. | `.agents/skills/`, hooks, `just` recipes. |
| **Effort**: the method | *cheshta*, *abhyasa* (YS 1.12-1.14) | Repeatable practice beats heroics. The method is a loop that can be run again. | The lifecycle in section 6. |
| **The unseen**: what is not in your control | *daiva* (Gita 18.14) | Design for variance you cannot control: model changes, upstream changes, flaky infrastructure. Pin, measure, retry honestly. | Pinned versions, evals, no silent rewriters (ADR-004). |
| **Purpose**: why | *lokasamgraha* (Gita 3.20-25) | Work serves the whole (users, teammates, the commons), not the worker or the metric. Defaults are conduct others will copy (Gita 3.21). | Safe defaults in the template: a default is a moral choice (see memory in #20). |
| **Motive**: how it is held | *nishkama karma* (Gita 2.47) | Own the action, not the result. Do the work well; do not bend it to a number. | Metrics observe; they never become the target (see Goodhart note in section 3). |
| **Quality**: how well | *gunas* (Gita 14, 18.23-28) | See section 5: a self-check on whether the work is clear, driven or deluded. | Judgement rubric in `dev-coach`. |
| **Evidence**: how we know | *pramana* (Nyaya Sutra 1.1.3) | See section 4: a claim enters the system with a named means of knowing. | Check scripts, evals, "vendor-reported" labels. |
| **Obligation**: what must happen | *nitya, naimittika, kamya, nishiddha* (Mimamsa) | See section 7: every rule is classified before it is written. | Chassis buckets A-D. |
| **Return**: giving back | *yajna* (Gita 3.9-16), *rina* | Work that only takes is a defect. What is learned is offered back, with credit. | Spread: upstreaming, attribution, release notes. |
| **Ending**: letting go | *tyaga*, *vairagya* (Isha 1, YS 1.12) | Nothing is kept for its own sake, including the instruction that made it. | Prune. |

## 3. Motive: act without attachment to the result

*karmany evadhikaras te ma phaleshu kadachana* (Gita 2.47): you have a right to the action, not
to its fruits. The verse does not say fruits do not matter. It says the work is judged by
whether it was done rightly, and that clinging to the result distorts the doing.

Engineering reading: **a metric is an observation, never a target.** Once a number is the aim
(coverage, skill count, invocations, pass rate) the system learns to produce the number. The
ratchet in chassis is acceptable because it is a floor on a discipline, not a goal; a score
that rewards creating skills would produce thousands of them. The prune stage exists to
counter exactly that.

Practical rules:
- Report the number and the way it was measured, not a verdict that the number is good.
- Evals that pass 70-90% of the time and track a trend are more honest than a gate engineered
  to pass 100% (Uber's finding, vendor-reported, which agrees with this reading).
- An agent proposing a change states the observation behind it, not that the change "improves
  the score".

## 4. Evidence: how a claim enters the system

Nyaya names the valid means of knowing (*pramana*): **perception** (*pratyaksha*), **inference**
(*anumana*), **testimony** (*shabda*) and **analogy** (*upamana*) (Nyaya Sutra 1.1.3). Vedanta
and Mimamsa add **non-perception** (*anupalabdhi*), the knowledge of an absence.

The ordering below is a choice made here. The schools do not rank them identically.

| Rank | Pramana | In practice | Example |
|---|---|---|---|
| 1 | *pratyaksha* | Ran it and saw the result. | A check script that fails, then passes. |
| 2 | *anumana* | Reasoned from observed facts. | "The hook prints line X unconditionally, so it prints it when the tool is absent" (then confirm by running). |
| 3 | *shabda* | A source says so. Weight depends on the source. | A vendor blog post. Label it "vendor-reported". |
| 4 | *upamana* | It worked for someone similar. | "Uber does this at 5,000 skills." Suggestive only. |

Anupalabdhi gives the rule for pruning: **"never used" is a valid conclusion only if the
instrument could have observed use.** No run log means no right to conclude non-use. This is why
the run log comes before the prune step.

Rules:
- A change to a steering file cites at least one claim of rank 1 or 2.
- Rank 3 and 4 material is labelled as such wherever it is repeated.
- Where claims conflict, higher rank wins; ties go to the human.

## 5. Quality of action: the three gunas as a self-check

Gita 18.23-25 describes three qualities of action, and 18.26-28 the doer behind each. Used here
as a **diagnostic the system applies to itself**. It is a judgement rubric, not a gate.

| | Sattvic (clear) | Rajasic (driven) | Tamasic (deluded) |
|---|---|---|---|
| **Action** | Done as required, free of attachment, without liking or aversion. | Done to get something, with ego and great effort. | Taken up from confusion, ignoring consequence, loss, harm, and one's own capacity (18.25). |
| **Doer** | Steady, unmoved by success or failure. | Eager for the result, moved by gain and loss. | Undisciplined, stubborn, procrastinating. |
| **Knowledge** | Sees one underlying whole in the many (18.20). | Sees only separateness. | Clings to one part as if it were the whole (18.22). |
| **In this system** | Right-sized skills traceable to a stated purpose; one source of truth; willing to be deleted. | Skill sprawl, goldplating, chasing a metric, unverified claims of success. | Autonomous action with no gate, no verification, destructive or irreversible steps, ignoring the agent's own limits; one eval treated as the whole truth. |

Using it: when `dev-coach` reviews a skill or a change, it asks which column the work sits in
and names the signs. Tamasic signs block; rajasic signs prompt pruning; sattvic work is left
alone. The tamasic column is the justification for the one-way-door denies (ADR-011): the
work that ignores consequence and capacity is the work to stop mechanically.

## 6. The loop (the wheel)

Gita 3.9-16 describes work as a **wheel** (*chakra*) of reciprocal offering: what is received
is returned, and the cycle keeps everything fed. A system that only consumes (takes learning, gives
nothing back) breaks the wheel (3.16). The six stages map to Uber's loop, each with its
Vedic root.

```
        Capture ──▶ Run ──▶ Observe
          ▲                    │
          │                    ▼
        Spread ◀── Prune ◀── Fix
```

| Stage | Root | Principle | Output |
|---|---|---|---|
| **1 Capture** | *sankalpa*: the stated intent made before an act | Write the purpose, the allowed and forbidden actions and the definition of done before the skill exists. The spec comes first. | A skill with a stated purpose and an owner. |
| **2 Run** | *nishkama karma* (Gita 2.47) | The skill does its work without reaching for the outcome. It reports what happened, not what would look good. | A record: which skill, which version, who invoked it. No prompt text or file contents. |
| **3 Observe** | *sakshi* (witness; Gita 13.22 *upadrashta*; Shvetashvatara 6.11), *svadhyaya* (Taittiriya 1.11) | The observer is not the doer. Friction is logged by the agent; judgement of it is made separately, in a fresh context. | Friction log (chassis#22), run log. |
| **4 Fix** | *viveka* (discernment), *prayashchitta* (corrective rite, Mimamsa) | Decide whether this is a skill problem, a rule problem or noise. If a mistake was mechanical, replace the instruction with a check. The correction is made once and made durable. | A proposed change with its evidence (section 4). |
| **5 Prune** | *tyaga* (Isha 1), *vairagya*, *aparigraha* (YS 2.30) | Remove what no longer earns its place: unused, no lift, superseded, or made redundant by a better model. Words are removed as well as skills. | A deletion, with the evidence for it. |
| **6 Spread** | *yajna*, *pravachana* (Taittiriya 1.11), *rina* | Offer what proved useful to the wider set, with credit to its source. | A promotion (project to template, upstream), with attribution. |

YS 1.12 names the two forces that still the mind: **practice** (*abhyasa*) and **non-attachment**
(*vairagya*). The loop has the same two halves: stages 1-4 are practice (build, run, watch,
correct); stage 5 is non-attachment (let go). Without 5 the system hoards. Without 1-4 it has
nothing worth keeping. YS 1.14 adds that practice takes root when done for a long time,
without a break, and with care: run the loop continuously, not as a one-off cleanup.

Two stages carry duties other stages do not:
- **Observe** and **Spread** are the two things the Taittiriya Upanishad (1.11) says not to
  neglect: self-study (*svadhyaya*) and teaching (*pravachana*).
- **Spread** is also where debt is paid. The tradition speaks of obligations to teachers and
  to those who came before (*rina*); the plain reading here is attribution and licence
  hygiene for anything adapted from someone else's work.

## 7. Classifying every rule before writing it

Mimamsa sorts prescribed action into four kinds, plus the corrective:

| Kind | Meaning | Chassis bucket | Examples |
|---|---|---|---|
| **Nitya** (always) | Obligatory, regular, no occasion needed. | A and B: always-on gates and ratchets | CI, lint, coverage ratchet, AGENTS.md size cap. |
| **Naimittika** (on occasion) | Required when a specific event occurs. | C: on-demand | `/arch-review` after a component change, `/security-audit` before release, `/dev-coach` after a correction. |
| **Kamya** (desire-driven) | Optional, done to reach a chosen aim. | Opt-in Copier questions | `ub-mode`, AI Engineer Coach, release automation. |
| **Nishiddha** (prohibited) | Not to be done. | Deny rules, forbidden patterns | `--no-verify`, force-push, `reset --hard`, hardcoded secrets. |
| **Prayashchitta** (corrective) | What to do after a lapse. | Fix stage | Incident leads to a deterministic check. |

Rule: **a new instruction is classified first.** A nitya rule that can be mechanical must be a
gate. A naimittika rule names its trigger. A kamya rule is opt-in and says what it is for. A
nishiddha rule is enforced by a deny, not by prose. A rule that fits none of these is probably
a no-op.

## 8. Morality: the constraints that do not adapt

The yamas (YS 2.30) are the tradition's restraints. They sit at the principle layer. They are
constraints on the loop, not outputs of it.

| Restraint | Meaning | Rule | Enforced by |
|---|---|---|---|
| **Satya** (truthfulness) | Say what is so, as it is known. (Taittiriya 1.11 *satyam vada*; Mundaka 3.1.6 *satyam eva jayate*) | No instruction states a falsehood; no result is reported as better than measured; unknown is stated as unknown. | Hook prints only what is true (#20 item 2); `continue-on-error` forbidden; claims carry their pramana. |
| **Ahimsa** (non-harm) | Do not injure, including by omission. | Irreversible and outward-facing actions need a human. Private data does not become public by default. | One-way-door denies (ADR-011); memory link off by default (#20 item 3). |
| **Asteya** (non-taking) | Do not take what was not given. | Adapted work keeps its licence and credit. | Skills adapted from upstream carry their LICENSE and an "Adaptations" note (as `ub-mode`, `security-audit`); extend the #21 gate to require it. |
| **Brahmacharya** (restraint) | Spend energy with care. | Context and attention are the scarce resource. Load only what the task needs. | Progressive disclosure; description length; AGENTS.md cap. |
| **Aparigraha** (non-hoarding) | Do not accumulate beyond need. | A skill earns its place or goes. | Size gates (#21); prune stage. |

The niyamas (YS 2.32) are the observances:

| Observance | Meaning | Rule | Enforced by |
|---|---|---|---|
| **Shaucha** (cleanliness) | Keep the working surface clean. | Lint, format, no dead files, valid frontmatter. | Pre-commit, `_ci-skills` (#21). |
| **Santosha** (contentment) | Know when it is enough. | Every task and skill has a stop condition. No work for its own sake. | Completion criteria in skills; laziness protocol in `ub-mode`. |
| **Tapas** (discipline) | Keep the standard when it is inconvenient. | Gates are not skipped. A failing gate is fixed, not bypassed. | `--no-verify` denied; self-weakening opengrep rules. |
| **Svadhyaya** (self-study) | Study one's own work. | The system reads its own record. | Observe stage; `dev-coach`. |
| **Ishvara pranidhana** (offering up) | Hand the work over rather than own it. | The doer offers the result for review and does not self-approve. Read here as an analogy, not a theological claim. | Autonomy ceiling, below. |

## 9. Authority and autonomy

Three ideas from the tradition fix who may change what.

**Adhikara (eligibility).** The Gita's *adhikara* (2.47) is the standing to act. In the Vedic
schools, study and rites were open to those qualified for them. Used here, in the role sense only
(not the social-hierarchy sense the tradition also carries, which this document does not adopt):
**autonomy is earned by demonstrated fitness, per task type, and is revocable.**

**Sakshi (witness).** The observer is a different position from the doer. In practice: review and
evaluation run in a fresh context, with a different actor from the one that made the change
(the existing review how-to already says this).

**Precedence.** Mimamsa ranks sources of authority: direct revelation over remembered
tradition over custom, when they conflict. The same order applies here:

> deterministic gate > ADR / principle > AGENTS.md > skill > memory or habit

(Chassis already says `AGENTS.md` wins over `ub-mode`.) A skill that contradicts a gate loses.

From these, the **autonomy ceiling**:

| Level | Who | Allowed |
|---|---|---|
| 0 | agent | Log friction, record a run. |
| 1 | agent | File an issue proposing a change, with evidence. |
| 2 | agent | Open a draft change to a skill or rule. |
| 3 | human | Approve and merge a change to any steering file. |
| 4 | human | Change a principle (this document, an ADR). |

No agent holds levels 3 or 4, however green CI is. An agent that can edit the check can make any
change pass it (the reason the gates are under CODEOWNERS). Steering files are `AGENTS.md`,
`.agents/skills/**`, `.claude/**`, `.codex/**` and prompts. A curator that silently rewrites
them is an interceptor on the agent's own instructions and is excluded by ADR-004.

Emergencies: the tradition recognises *apad-dharma*, the allowance for breaking an ordinary
rule under distress. This system grants that power to a human only, never an agent, and it
leaves a record.

## 10. How the system adapts itself

**Unit of adaptation.** Any steering artifact: a skill, rule, prompt, hook or config.

**State of each artifact.** `proposed` (a draft with evidence) → `probation` (live, observed,
reviewed after a fixed period) → `established` → `dormant` (no recorded use, and the run log
exists, per anupalabdhi) → `retired`. State and `last_reviewed` live in the artifact's metadata.

**The adaptation protocol.**
1. Observe produces evidence (rank 1 or 2). Noise and one-off events are discarded.
2. Fix classifies it (section 7). Mechanical failures become checks, not words.
3. The change is proposed at level 1 or 2 with its evidence and the pramana ranks.
4. A human at level 3 decides. Fresh-context review is run first.
5. It enters on probation. The run log shows whether it is used and whether outcomes improved.
6. At review: promote, rewrite, or retire. Retirement is the default for anything with no lift.
7. Proven artifacts are offered upward (Spread) with credit.

**Self-diagnosis.** Periodically the system asks the guna questions (section 5) of its own
contents and reports the result. It does not act on it. It reports.

**The principles do not adapt in this loop.** If observation shows a principle is wrong, that is
a level 4 matter: a human writes an ADR. The only things the loop may weaken are practices.

## 11. Mapping to chassis and agnova

| Plane | Holds | Role |
|---|---|---|
| **Chassis template** | Principles (this doc), gates, skill scaffold, `dev-coach`, ADRs | Owns the invariants and the gates every project inherits. |
| **A stamped project** (e.g. agnova itself) | Its own skills and rules, its run and friction logs | Where practices are proven on real work. |
| **Agnova-scaffolded agent homes** | Runtime skills, memory, knowledge, daily notes | Where agents run unattended: the closest match to the system this describes, and so the place the same checks matter most. |

The existing pieces already realise much of this: chassis buckets A-D are section 7; ADR-011
is the nishiddha and ahimsa layer; ADR-004 is the exclusion of interceptors; `dev-coach` is
*svadhyaya*; the agent-change gate is the Fix gate; `copier update` is a Spread path.

## 12. What is missing, in order

1. This document, and an ADR recording sections 8-10 (the ceiling, the states, the protocol).
2. Skill hygiene gate (#21), extended with the asteya check (upstream provenance) and metadata
   fields (`owner`, `last_reviewed`, state).
3. Friction log (#22).
4. A run log, after a spike on whether a hook can see skill invocations.
5. `dev-coach`: the prune step (needs 4) and the guna-rubric report.
6. Ablation evals for one skill (needs real prompts to replay).
7. In agnova: the same checks for agent homes (agnova#20), then a curator for agent homes, after
   the message round trip in agnova#2 is verified.

## 13. Limits of this framing

- The mapping is an interpretation. A reader trained in the tradition may disagree with any row.
- The tradition has teachings that cut against parts of this: the Gita's non-attachment to results
  sits uneasily beside a system that measures results continuously. The resolution used here
  (measure to observe, never to aim) is a choice.
- The guna rubric is subjective. It guides review, and it does not replace the checks.
- Nothing here is a reason to skip a check because a principle seems to be satisfied.
