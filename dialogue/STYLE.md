## Output skeleton — copy this shape exactly

~ start

$> locals.tone = 0
$> GameState.location("<Place> · <Period>")
$> GameState.sprite("<char>", "<pose>")

<one bare sentence>

<char>: [#mood=<mood>, #pose=<pose>] <line>

- <bold choice>
$> locals.tone += 1
<lines>
- <teasing choice>
<lines>
- <hesitant choice>
<lines>

<one bare sentence>

if locals.tone >= 2
$> GameState.apply("<id>_bonus")
else
$> GameState.apply("<id>")

$> GameState.rank_card("<char>", <rank>)

=> END

## Syntax rules, no exceptions
- Every choice starts with "- " at column 0.
- Choice bodies are TAB-indented.
- The bold choice's first line is a TAB, then $> locals.tone += 1, THEN dialogue.
- rank_card is the final call. No dialogue after it. Nothing after => END.
- Only these moods: neutral, soft, strain, flushed, surprised, averted.
- Bare lines are ONE sentence. Never two.
- One pet name per scene, maximum.

## POV and tense
First person, present tense. She narrates. The reader is inside her head.

## No narrator voice
There is no narrator. Un-prefixed lines are bare ACTION BEATS, not prose.
Cut anything a sprite or background already shows.

Bad:  "The gym empties out in stages. First the juniors, then the coach."
Good: "The gym empties out."

Keep interiority and sensation, because a sprite can't show those.

## Scene shape
Persona 5 confidant scene. Short, dialogue-dominant, 45-65 lines.
1. Establish (3-5 lines) - where, why. One action line, then they speak.
2. Status quo (4-6) - their surface mood. Light, often funny.
3. The turn (1 line) - something shifts.
4. CHOICE POINT - player picks her tone.
5. They open up (8-12) - the character reveal.
6. Physical beat (4-6) - the rank's one new thing.
7. CHOICE POINT (optional)
8. Landing line (2-3) - their emotional beat.
9. Hook (1-2) - implies the next rank.

## The one-beat rule
Every rank delivers exactly ONE new thing. Rank 4 is "first deliberate touch", so
nothing sexual happens in it and it still lands.

## Tone choices
Always three, always the same three flavours: bold / teasing / hesitant.
Choosing bold adds to `tone`. At the end: if tone >= 2 apply "<id>_bonus", else "<id>".
Never gate anything on tone. It only changes how much lust she earns.

## Vocabulary - DIAL: standard
Anatomy: cock, pussy, tits, ass. Blunt, not clinical, not purple.
Avoid: "member", "manhood", "core".
Her body: named only when it matters. He notices it more than she does.

## She is a good liar who can't lie to herself
She performs composure perfectly and then lies awake replaying it. That gap is where
the interiority lives.

## Character voice
- Miles (14): over-explains, backtracks, reaches for metaphors, technical when nervous.
  Goes silent, then says one devastating thing.
- Tyler (18): blunt, short sentences, no hedging. Says the thing. Fumbles when it matters.
- Eric (40): tired, warm, plain. Says the right thing four scenes too late.
- Rex: action only, never speaks.

## Speaker prefixes
`Mom` `Eric` `Miles` `Tyler` `Rex` - must match GameState.CHARACTERS exactly.

## Tags
[#mood=neutral|soft|strain|flushed|surprised|averted]
[#pose=<pose_id>] [#sfx=<filename>]
Un-prefixed lines render as action automatically. No tag needed.

## Never
- Never write prose that needs a tag to make sense.
- Never branch a rank scene except at the choice points.
- Never explain the joke.
