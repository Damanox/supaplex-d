module objects.zonk;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import objects.infotron;
import objects.murphy;
import objects.reservation;
import interfaces;

// Zonk physics are a direct port of the StatefulLevelTile state machine in
// open-supaplex/src/supaplex.c (updateZonkTiles, ~line 2620). Every zonk
// carries a state byte (_state) that encodes its fall/slide phase. The
// state is advanced once per sim tick by Level._stepSim, top-to-bottom in
// linear grid order.
//
// State-family layout (matches C):
//   0x00        at rest — decide start-fall / start-slide
//   0x10..0x17  falling (8 ticks, cascade fires at 0x16)
//   0x20..0x27  post-slide-left transient (8 ticks, cascade at 0x26)
//   0x30..0x37  post-slide-right transient (8 ticks, cascade at 0x36)
//   0x40..0x42  start-fall transient (2 ticks, commits at 0x42)
//   0x50..0x52  slide-left in progress (2 ticks, commits at 0x52)
//   0x60..0x62  slide-right in progress (2 ticks, commits at 0x62)
//   0x70        fall-reservation transient (single-tick continuation)
class Zonk : GameObject, IPushable, ISlideable
{
    private Animation _stand;
    private Animation _down;
    private Animation _left;
    private Animation _right;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 8);
        _down = new Animation();
        _down.setSpriteSheet(_texture);
        _down.addTile(0, 8);
        _down.addTile(0, 8);
        _down.addTile(0, 8);
        _left = new Animation();
        _left.setSpriteSheet(_texture);
        _left.addTile(1, 8);
        _left.addTile(2, 8);
        _left.addTile(3, 8);
        _right = new Animation();
        _right.setSpriteSheet(_texture);
        _right.addTile(3, 8);
        _right.addTile(2, 8);
        _right.addTile(1, 8);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        auto res = MoveCheckResult.False;
        if(_state != 0)
            return res;
        if(_level.check(x, y + 1))
            return res;
        if(direction == MoveDirection.Left && _level.checkMove(x - 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        else if(direction == MoveDirection.Right && _level.checkMove(x + 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        if(res != MoveCheckResult.Push)
            return res;
        _pushed = true;
        if(direction == MoveDirection.Left)
            _currentAnimation = _left;
        else if(direction == MoveDirection.Right)
            _currentAnimation = _right;
        _level.move(this, direction);
        player.setPushAnimation(direction);
        return res;
    }

    public override void draw()
    {
        // Push moves still use the legacy animation-driven move path
        // (Level.move / AnimatedSprite.getLeftTime), so when the zonk is
        // being pushed we render by the sprite's remaining animation time.
        // The state-machine controlled fall/slide path uses the state byte
        // to compute an explicit sub-tile offset.
        if(_pushed && _moving)
        {
            auto animTime = _sprite.getFrameTime() * _sprite.getAnimation.getSize();
            if(_direction == MoveDirection.None)
                _sprite.position = Vector2f(_x * 32f, _y * 32f);
            else if(_direction == MoveDirection.Left)
                _sprite.position = Vector2f(_x * 32f + _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
            else if(_direction == MoveDirection.Right)
                _sprite.position = Vector2f(_x * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
            else if(_direction == MoveDirection.Down)
                _sprite.position = Vector2f(_x * 32f, _y * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs");
            _window.draw(_sprite);
            return;
        }

        // State-machine-driven render: compute a visual offset within the
        // current logical cell from the state byte. The move spans 10 sim
        // ticks; we derive a progress value P in [0, 1] and pick an
        // animation frame to convey motion. This replaces the old
        // sprite-driven interpolation (the sprite clock is ignored for
        // non-push moves).
        float visualX = _x * 32f;
        float visualY = _y * 32f;
        Animation anim = _stand;
        size_t frame = 0;

        // Interpolate within the current sim tick for smooth motion at
        // render rates higher than the 35 Hz physics rate. frac in [0,1).
        immutable float frac = _level.subTickFraction();

        // Fall covers a full tile of vertical motion across the 8 sub-
        // states 0x10..0x17, advancing 4 pixels per tick. Slides cover a
        // full tile of horizontal motion across the 8 sub-states
        // 0x50,0x51 (at origin) plus 0x22..0x27 (at destination). Both
        // share `tick = state & 0x0F`, which sequences cleanly across
        // the slide's state-family transition because 0x50→0x22 carries
        // the low-nibble forward (0,1,2,3,...7).
        auto family = _state & 0xF0;
        switch(family)
        {
            case 0x10: // falling, logical = destination (origin one row up)
                {
                    auto step = _state - 0x10;          // 0..7
                    visualY = _y * 32f - 32f + (step + frac) * 4f;
                    anim = _down;
                    frame = step % _down.getSize();
                }
                break;
            case 0x20: // post-slide-left, logical = destination (slid from x+1)
                {
                    auto tick = _state & 0x0F;          // 2..7
                    visualX = (_x + 1) * 32f - (tick + frac) * 4f;
                    anim = _left;
                    frame = tick % _left.getSize();
                }
                break;
            case 0x30: // post-slide-right, logical = destination (slid from x-1)
                {
                    auto tick = _state & 0x0F;          // 2..7
                    visualX = (_x - 1) * 32f + (tick + frac) * 4f;
                    anim = _right;
                    frame = tick % _right.getSize();
                }
                break;
            case 0x40: // start-fall: 2 ticks stationary at origin
                visualY = _y * 32f;
                anim = _stand;
                break;
            case 0x50: // slide-left in progress, logical = origin
                {
                    auto tick = _state & 0x0F;          // 0..1
                    visualX = _x * 32f - (tick + frac) * 4f;
                    anim = _left;
                    frame = tick % _left.getSize();
                }
                break;
            case 0x60: // slide-right in progress, logical = origin
                {
                    auto tick = _state & 0x0F;          // 0..1
                    visualX = _x * 32f + (tick + frac) * 4f;
                    anim = _right;
                    frame = tick % _right.getSize();
                }
                break;
            case 0x70: // fall-reservation transient: momentarily at rest
            default:
                visualX = _x * 32f;
                visualY = _y * 32f;
                anim = _stand;
                break;
        }

        if(_sprite.getAnimation() is null || _sprite.getAnimation() !is anim)
            _sprite.setAnimation(anim);
        _sprite.setFrame(frame, false);
        _sprite.position = Vector2f(visualX, visualY);
        _window.draw(_sprite);
    }

    public override void stop()
    {
        _currentAnimation = _stand;
        _sprite.play(_stand, null);
    }

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

    public override void updateState(Level level)
    {
        // Mid-push moves are managed by the legacy Level.move animation
        // path, not the state machine. Skip until the push animation's
        // finishMove brings the zonk to rest at its destination.
        if(_moving)
            return;

        // The C original's 0x70 continuation jumps back to the top of
        // updateZonkTiles with the new position and re-runs dispatch.
        // Emulate with a loop: _handleFallReservation returns true after
        // moving the zonk down so the freshly-set 0x10 state is also
        // advanced in the same tick (otherwise continuous falls would be
        // one tick slower than the C reference, cumulatively misaligning
        // the cascade windows).
        while(_stepOnce(level)) {}
    }

    // Returns true if the state machine should re-dispatch at the new
    // position in the same tick (only the 0x70 → 0x10 continuation case).
    private bool _stepOnce(Level level)
    {
        auto family = _state & 0xF0;
        switch(family)
        {
            // State-0 initialisation. C's updateZonkTiles does the
            // 0 → 0x40/0x50/0x60 transition at the top of the function
            // and then FALLS THROUGH to the main dispatch loop, which
            // runs the 0x40/0x50/0x60 handler once in the same call
            // (advancing one more sub-state). We emulate this by
            // re-dispatching if _handleAtRest actually transitioned
            // out of state 0.
            case 0x00:
                _handleAtRest(level);
                return _state != 0;
            case 0x10: _handleFalling(level); return false;
            case 0x20: _handlePostSlideLeft(level); return false;
            case 0x30: _handlePostSlideRight(level); return false;
            case 0x40: _handleStartFall(level); return false;
            case 0x50: _handleSlideLeft(level); return false;
            case 0x60: _handleSlideRight(level); return false;
            case 0x70: return _handleFallReservation(level);
            default: return false;
        }
    }

    // state 0x00: at rest. Decide whether to start falling, slide-left,
    // or slide-right. Any triggered transition sets the state byte and
    // returns; the actual motion begins on subsequent ticks.
    private void _handleAtRest(Level level)
    {
        // Fall has highest priority: if the cell below is empty space,
        // begin the start-fall transient.
        if(level.isSpace(_x, _y + 1))
        {
            _state = 0x40;
            return;
        }

        // Slide prerequisite: below must be a resting slide-support tile
        // (Zonk / Infotron / RamChip centre at state 0). Anything else
        // (Hardware, Wall, Murphy, mid-animation object) blocks the slide.
        if(!level.isRestingSlideSupport(_x, _y + 1))
            return;

        // Slide-left: belowLeft must be Space or a Slide/AltSpace
        // reservation; left cell must be empty Space. Plant a Slide
        // reservation on the destination (left cell) so concurrent
        // cascades see the cell as claimed this tick.
        if(level.isSpaceOrReservation(_x - 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace))
        {
            if(level.isSpace(_x - 1, _y))
            {
                _state = 0x50;
                level.reserve(_x - 1, _y, ReservationKind.Slide);
                return;
            }
        }

        // Slide-right: mirror of slide-left. C's right-cell gate has an
        // additional clause we must reproduce verbatim: right cell may
        // be a Fall reservation (0x99) IFF aboveRight is a resting
        // Zonk. Without this, a zonk that could slide-right over a
        // cell another zonk is about to fall into instead stays put,
        // diverging from C's final settled pile.
        if(level.isSpaceOrReservation(_x + 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace))
        {
            bool rightOk = level.isSpace(_x + 1, _y);
            if(!rightOk && level.isSpaceOrReservation(_x + 1, _y, ReservationKind.Fall))
            {
                auto aboveRight = cast(Zonk)level.get(_x + 1, _y - 1);
                if(aboveRight !is null && aboveRight.state == 0 && !aboveRight.moving)
                    rightOk = true;
            }
            if(rightOk)
            {
                _state = 0x60;
                level.reserve(_x + 1, _y, ReservationKind.Slide);
                return;
            }
        }
    }

    // state 0x10..0x17 (plus the 0x18 completion pseudo-state).
    // Advance one sub-tick. At 0x16 the falling-cascade fires for the
    // pre-fall cell (position above us, which holds our Cleared
    // reservation from the 0x42 commit). At 0x18 the fall ends and we
    // evaluate continuation: a further fall into empty space (→ 0x70),
    // an explosion trigger, or a pile-slide initialisation if we landed
    // on a resting pile.
    private void _handleFalling(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);

        if(newState == 0x16)
        {
            _state = 0x16;
            cascadeAfterZonkFall(level, _x, _y - 1);
            return;
        }
        if(newState < 0x18)
        {
            _state = newState;
            return;
        }

        // Fall completes.
        _state = 0;

        // Continuation: if directly below is Space or a Fall reservation
        // (the reservation we planted on a prior 0x18 → 0x70 transition),
        // enter the 0x70 fall-reservation transient.
        if(level.isSpaceOrReservation(_x, _y + 1, ReservationKind.Fall))
        {
            _state = 0x70;
            level.reserve(_x, _y + 1, ReservationKind.Fall);
            return;
        }

        // Landing-on-Murphy: explode Murphy's cell (matches the C
        // handler's direct detonation when belowTile is Murphy).
        auto below = level.get(_x, _y + 1);
        if(below !is null && typeid(below) == typeid(Murphy) && !below.moving)
        {
            level.explode(below.x, below.y);
            return;
        }

        // If below isn't a resting pile tile, we're fully at rest — the
        // only remaining case to handle is initialisation of a slide off
        // the top of a pile (same logic as state 0x00 slide gate).
        if(!level.isRestingSlideSupport(_x, _y + 1))
            return;

        // Pile-slide-left initialisation.
        if(level.isSpaceOrReservation(_x - 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace))
        {
            if(level.isSpace(_x - 1, _y))
            {
                _state = 0x50;
                level.reserve(_x - 1, _y, ReservationKind.Slide);
                return;
            }
        }

        // Pile-slide-right initialisation.
        if(level.isSpaceOrReservation(_x + 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace))
        {
            if(level.isSpace(_x + 1, _y))
            {
                _state = 0x60;
                level.reserve(_x + 1, _y, ReservationKind.Slide);
                return;
            }
        }
    }

    // state 0x20..0x27 post-slide-left. The zonk is already at the
    // destination cell (logical _x = origin - 1). At sub-state 0x24 we
    // plant an AltSpace sibling-marker on the origin cell so the
    // cascade sees it as slide-acceptable transient space. At 0x26 the
    // post-slide cascade fires for the origin (_x + 1). At 0x28 the
    // transient ends and the zonk transitions to falling on the cell
    // directly below.
    private void _handlePostSlideLeft(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);

        if(newState == 0x24)
        {
            _state = newState;
            if(_x + 1 < 60)
                level.reserve(_x + 1, _y, ReservationKind.AltSpace);
            return;
        }
        if(newState == 0x26)
        {
            _state = newState;
            cascadeAfterZonkFall(level, _x + 1, _y);
            return;
        }
        if(newState < 0x28)
        {
            _state = newState;
            return;
        }

        // Commit at 0x28: the zonk moves down one cell into the cell
        // below the slide destination and enters the fall state machine
        // at 0x10. The former slide-destination becomes a Cleared
        // reservation (the 0x16 cascade of the upcoming fall will turn
        // it back into Space). Matches C's unconditional
        //   currentTile = 0xFF/0xFF; belowTile = Zonk/0x10.
        // If another mover happens to sit at below-destination now, it
        // gets overwritten (orphaned) — C does the same, and any pile
        // of identity-shifted zonks converges to the same final grid
        // state because state-machine iteration works by cell position,
        // not object identity.
        immutable int sx = _x;
        immutable int sy = _y;
        _y = sy + 1;
        level.setCell(_x, _y, this);
        level.reserve(sx, sy, ReservationKind.Cleared);
        _state = 0x10;
    }

    // state 0x30..0x37 post-slide-right. Mirror of post-slide-left.
    private void _handlePostSlideRight(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);

        if(newState == 0x34)
        {
            _state = newState;
            if(_x - 1 >= 0)
                level.reserve(_x - 1, _y, ReservationKind.AltSpace);
            return;
        }
        if(newState == 0x36)
        {
            _state = newState;
            cascadeAfterZonkFall(level, _x - 1, _y);
            return;
        }
        if(newState < 0x38)
        {
            _state = newState;
            return;
        }

        // Commit at 0x38: mirror of 0x28 — unconditional move down,
        // overwriting any occupant (matches C).
        immutable int sx = _x;
        immutable int sy = _y;
        _y = sy + 1;
        level.setCell(_x, _y, this);
        level.reserve(sx, sy, ReservationKind.Cleared);
        _state = 0x10;
    }

    // state 0x40..0x42 start-fall transient at the origin cell. Advance
    // two ticks then commit by moving the zonk into the cell below; if
    // below is no longer space at commit time, decrement and wait.
    private void _handleStartFall(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);
        if(newState < 0x42)
        {
            _state = newState;
            return;
        }

        if(!level.isSpace(_x, _y + 1))
        {
            // Below filled up underneath us — back off a tick and retry.
            _state = cast(ubyte)(newState - 1);
            return;
        }

        // Commit: origin becomes a Cleared reservation, zonk relocates
        // one cell down, state becomes 0x10 (falling). The reservation
        // at origin is torn down by the falling cascade at state 0x16.
        immutable int ox = _x;
        immutable int oy = _y;
        _x = ox;
        _y = oy + 1;
        level.setCell(_x, _y, this);
        level.reserve(ox, oy, ReservationKind.Cleared);
        _state = 0x10;
    }

    // state 0x50..0x52 slide-left in progress at the origin. Advance
    // two ticks then commit by moving the zonk one cell to the left,
    // leaving a Cleared reservation at the origin and (if the cell
    // below the destination is empty) a Cleared reservation there as
    // a guard for the 0x20 post-slide transient.
    private void _handleSlideLeft(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);
        if(newState < 0x52)
        {
            _state = newState;
            return;
        }

        // Commit gate (matches C's 0x52 check exactly):
        //   belowLeft must be strict Space (no reservation). The initial
        //   state-0 slide gate accepted Slide/AltSpace there, but at
        //   commit time we require Space — another mover's reservation
        //   means they're about to land in that cell, and clobbering it
        //   strands them in a permanent-stuck commit-retry loop.
        //   leftCell must be Space or our own Slide reservation (planted
        //   at state 0).
        if(!level.isSpace(_x - 1, _y + 1))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }
        if(!level.isSpaceOrReservation(_x - 1, _y,
                ReservationKind.Slide))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }

        immutable int ox = _x;
        immutable int oy = _y;
        _x = ox - 1;
        _y = oy;
        level.setCell(_x, _y, this);
        level.reserve(ox, oy, ReservationKind.Cleared);
        // The C original plants a Cleared sentinel below the slide
        // destination too (to block other movers during the 0x20..0x28
        // transient). We only do so if that cell is *actually* Space —
        // a Slide reservation already sitting there belongs to another
        // mover's concurrent slide toward the same cell, and clobbering
        // it with Cleared strands that mover forever (commit perpetually
        // finds its own reservation gone). Leaving the other mover's
        // reservation alone means we may race with them at our 0x28
        // commit, which is handled there.
        if(level.isSpace(_x, _y + 1))
            level.reserve(_x, _y + 1, ReservationKind.Cleared);
        _state = 0x22;
    }

    // state 0x60..0x62 slide-right in progress. Mirror of slide-left.
    private void _handleSlideRight(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);
        if(newState < 0x62)
        {
            _state = newState;
            return;
        }

        // Commit gate: belowRight strict Space; rightCell Space or our
        // own Slide reservation. See _handleSlideLeft for rationale.
        if(!level.isSpace(_x + 1, _y + 1))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }
        if(!level.isSpaceOrReservation(_x + 1, _y,
                ReservationKind.Slide))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }

        immutable int ox = _x;
        immutable int oy = _y;
        _x = ox + 1;
        _y = oy;
        level.setCell(_x, _y, this);
        level.reserve(ox, oy, ReservationKind.Cleared);
        if(level.isSpace(_x, _y + 1))
            level.reserve(_x, _y + 1, ReservationKind.Cleared);
        _state = 0x32;
    }

    // state 0x70 fall-reservation transient. Below must be Space or our
    // own previously-planted Fall reservation. On success, move the
    // zonk into that cell and re-enter falling at 0x10 in the same
    // tick (returning true so updateState's loop re-dispatches).
    private bool _handleFallReservation(Level level)
    {
        if(!level.isSpaceOrReservation(_x, _y + 1, ReservationKind.Fall))
            return false;

        immutable int ox = _x;
        immutable int oy = _y;
        _x = ox;
        _y = oy + 1;
        level.setCell(_x, _y, this);
        level.reserve(ox, oy, ReservationKind.Cleared);
        _state = 0x10;
        return true;
    }
}

// Falling-cascade: called at state 0x16 of a falling zonk with (x, y)
// set to the pre-fall origin cell (currently a Cleared reservation). At
// state 0x26 / 0x36 of post-slide transients it's called with the
// slide's origin cell. Port of handleZonkStateAfterFallingOneTile in
// supaplex.c (~line 3802).
//
// Behaviour:
//   1. Clear (x, y) to Space (unless an Explosion is already there).
//   2. Gate: the cell above (x, y-1) must be empty Space OR a Fall
//      reservation whose aboveAboveTile is a resting Infotron.
//   3. Branch A — aboveLeft is a resting zonk AND leftCell is a resting
//      slide-support (Zonk / Infotron / RamChip-centre): set aboveLeft
//      state to 0x60 (slide-right) and mark aboveTile with a Slide
//      reservation.
//   4. Branch B — aboveRight is a resting zonk AND rightCell is a
//      resting slide-support: set aboveRight state to 0x50 (slide-left)
//      and mark aboveTile with a Slide reservation.
//   Only one branch fires per call (Branch A first).
void cascadeAfterZonkFall(Level level, int x, int y)
{
    // (1) Initial clear. If an Explosion occupies (x, y) we leave it —
    // the explosion timer owns that cell.
    auto at = level.get(x, y);
    if(at !is null && typeid(at) != typeid(objects.explosion.Explosion))
        level.clearCell(x, y);

    // (2) Gate. The aboveTile (one row up from the vacated cell) must be
    // empty Space, or a Fall reservation with an Infotron above it.
    if(y <= 0)
        return;
    if(!level.isSpace(x, y - 1))
    {
        if(!level.isSpaceOrReservation(x, y - 1, ReservationKind.Fall))
            return;
        if(y - 2 < 0)
            return;
        // C only checks aboveAbove tile type, not state — a mid-fall
        // infotron here still gates the cascade through.
        auto aboveAbove = level.get(x, y - 2);
        if(aboveAbove is null || cast(Infotron)aboveAbove is null)
            return;
    }

    // (3) Branch A: aboveLeft resting zonk, leftCell resting support.
    if(x - 1 >= 0 && y - 1 >= 0)
    {
        auto aboveLeft = cast(Zonk)level.get(x - 1, y - 1);
        if(aboveLeft !is null
            && aboveLeft.state == 0
            && !aboveLeft.moving
            && level.isRestingSlideSupport(x - 1, y))
        {
            aboveLeft.state = 0x60; // slide-right
            level.reserve(x, y - 1, ReservationKind.Slide);
            // The support cell the slide will enter at state 0x62 is
            // the cell where we're currently resting (x, y-1). Reserve
            // it too so other movers don't grab it. Actually the slide
            // reservation above already claims the destination above-
            // right of the support zonk; no additional reservation
            // needed here beyond the one the zonk places when it
            // transitions from 0x00 to 0x60. The aboveTile 0x88 marker
            // mirrors the C original exactly.
            return;
        }
    }

    // (4) Branch B: aboveRight resting zonk, rightCell resting support.
    if(x + 1 < 60 && y - 1 >= 0)
    {
        auto aboveRight = cast(Zonk)level.get(x + 1, y - 1);
        if(aboveRight !is null
            && aboveRight.state == 0
            && !aboveRight.moving
            && level.isRestingSlideSupport(x + 1, y))
        {
            aboveRight.state = 0x50; // slide-left
            level.reserve(x, y - 1, ReservationKind.Slide);
            return;
        }
    }
}

// Import delayed to avoid a module-init cycle with objects.explosion.
private import objects.explosion;
