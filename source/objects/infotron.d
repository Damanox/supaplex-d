module objects.infotron;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import interfaces;
import objects.zonk;
import objects.murphy;
import objects.reservation;
import objects.explosion;

// Infotron physics are the symmetric sibling of Zonk's. Same state-family
// layout; the cascade is separate (infotron-on-infotron only) and slide
// commits leave a Fall reservation on the cell below the destination
// rather than Zonk's Cleared reservation — this mirrors the C original's
// use of 0x99 (infotron) vs 0xFF (zonk) commit markers.
class Infotron : GameObject, IConsumable, ISlideable
{
    private Animation _stand;
    private Animation _down;
    private Animation _left;
    private Animation _right;
    private Animation _disappear;
    private bool _disappearing;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 6);
        _down = new Animation();
        _down.setSpriteSheet(_texture);
        _down.addTile(0, 6);
        _down.addTile(0, 6);
        _down.addTile(0, 6);
        _left = new Animation();
        _left.setSpriteSheet(_texture);
        _left.addTile(7, 6);
        _left.addTile(6, 6);
        _left.addTile(5, 6);
        _left.addTile(4, 6);
        _left.addTile(3, 6);
        _left.addTile(2, 6);
        _left.addTile(1, 6);
        _right = new Animation();
        _right.setSpriteSheet(_texture);
        _right.addTile(1, 6);
        _right.addTile(2, 6);
        _right.addTile(3, 6);
        _right.addTile(4, 6);
        _right.addTile(5, 6);
        _right.addTile(6, 6);
        _right.addTile(7, 6);
        _disappear = new Animation();
        _disappear.setSpriteSheet(_texture);
        _disappear.addTile(8, 6);
        _disappear.addTile(9, 6);
        _disappear.addTile(10, 6);
        _disappear.addTile(11, 6);
        _disappear.addTile(12, 6);
        _disappear.addTile(13, 6);
        _disappear.addTile(14, 6);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
    }

    public override void startDisappear()
    {
        _disappearing = true;
        _currentAnimation = _disappear;
        _sprite.setFrameTime(dur!"msecs"(50));
        _sprite.play(_disappear, &stopDisappear);
    }

    public override void stopDisappear()
    {
        stop();
        _level.destroy(x, y);
    }

    public override void draw()
    {
        // Disappear animation runs on the sprite's internal clock; draw
        // with the sprite's current frame, no state-derived offset.
        if(_disappearing)
        {
            _sprite.position = Vector2f(_x * 32f, _y * 32f);
            _window.draw(_sprite);
            return;
        }

        float visualX = _x * 32f;
        float visualY = _y * 32f;
        Animation anim = _stand;
        size_t frame = 0;

        auto family = _state & 0xF0;
        switch(family)
        {
            case 0x10:
                {
                    auto step = _state - 0x10;          // 0..7
                    visualY = _y * 32f - 32f + step * 4f;
                    anim = _down;
                    frame = step % _down.getSize();
                }
                break;
            case 0x20:
                {
                    auto tick = _state & 0x0F;          // 2..7
                    visualX = (_x + 1) * 32f - tick * 4f;
                    anim = _left;
                    frame = tick % _left.getSize();
                }
                break;
            case 0x30:
                {
                    auto tick = _state & 0x0F;          // 2..7
                    visualX = (_x - 1) * 32f + tick * 4f;
                    anim = _right;
                    frame = tick % _right.getSize();
                }
                break;
            case 0x40:
                visualY = _y * 32f;
                anim = _stand;
                break;
            case 0x50:
                {
                    auto tick = _state & 0x0F;          // 0..1
                    visualX = _x * 32f - tick * 4f;
                    anim = _left;
                    frame = tick % _left.getSize();
                }
                break;
            case 0x60:
                {
                    auto tick = _state & 0x0F;          // 0..1
                    visualX = _x * 32f + tick * 4f;
                    anim = _right;
                    frame = tick % _right.getSize();
                }
                break;
            case 0x70:
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
        _disappearing = false;
        _currentAnimation = _stand;
        _sprite.setFrameTime(dur!"msecs"(100));
        _sprite.play(_stand, null);
    }

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

    public override void updateState(Level level)
    {
        if(_moving || _disappearing)
            return;

        while(_stepOnce(level)) {}
    }

    private bool _stepOnce(Level level)
    {
        auto family = _state & 0xF0;
        switch(family)
        {
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

    private void _handleAtRest(Level level)
    {
        if(level.isSpace(_x, _y + 1))
        {
            _state = 0x40;
            return;
        }

        if(!level.isRestingSlideSupport(_x, _y + 1))
            return;

        if(level.isSpaceOrReservation(_x - 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace,
                ReservationKind.Fall))
        {
            if(level.isSpace(_x - 1, _y))
            {
                _state = 0x50;
                level.reserve(_x - 1, _y, ReservationKind.Slide);
                return;
            }
        }

        if(level.isSpaceOrReservation(_x + 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace,
                ReservationKind.Fall))
        {
            if(level.isSpace(_x + 1, _y))
            {
                _state = 0x60;
                level.reserve(_x + 1, _y, ReservationKind.Slide);
                return;
            }
        }
    }

    private void _handleFalling(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);

        if(newState == 0x16)
        {
            _state = 0x16;
            cascadeAfterInfotronFall(level, _x, _y - 1);
            return;
        }
        if(newState < 0x18)
        {
            _state = newState;
            return;
        }

        _state = 0;

        if(level.isSpaceOrReservation(_x, _y + 1, ReservationKind.Fall))
        {
            _state = 0x70;
            level.reserve(_x, _y + 1, ReservationKind.Fall);
            return;
        }

        auto below = level.get(_x, _y + 1);
        if(below !is null && typeid(below) == typeid(Murphy) && !below.moving)
        {
            level.explode(below.x, below.y);
            return;
        }

        if(!level.isRestingSlideSupport(_x, _y + 1))
            return;

        if(level.isSpaceOrReservation(_x - 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace,
                ReservationKind.Fall))
        {
            if(level.isSpace(_x - 1, _y))
            {
                _state = 0x50;
                level.reserve(_x - 1, _y, ReservationKind.Slide);
                return;
            }
        }

        if(level.isSpaceOrReservation(_x + 1, _y + 1,
                ReservationKind.Slide, ReservationKind.AltSpace,
                ReservationKind.Fall))
        {
            if(level.isSpace(_x + 1, _y))
            {
                _state = 0x60;
                level.reserve(_x + 1, _y, ReservationKind.Slide);
                return;
            }
        }
    }

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
            cascadeAfterInfotronFall(level, _x + 1, _y);
            return;
        }
        if(newState < 0x28)
        {
            _state = newState;
            return;
        }

        // Commit at 0x28 — unconditional move down (matches C). See zonk.d.
        immutable int sx = _x;
        immutable int sy = _y;
        _y = sy + 1;
        level.setCell(_x, _y, this);
        level.reserve(sx, sy, ReservationKind.Cleared);
        _state = 0x10;
    }

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
            cascadeAfterInfotronFall(level, _x - 1, _y);
            return;
        }
        if(newState < 0x38)
        {
            _state = newState;
            return;
        }

        immutable int sx = _x;
        immutable int sy = _y;
        _y = sy + 1;
        level.setCell(_x, _y, this);
        level.reserve(sx, sy, ReservationKind.Cleared);
        _state = 0x10;
    }

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
            _state = cast(ubyte)(newState - 1);
            return;
        }

        immutable int ox = _x;
        immutable int oy = _y;
        _x = ox;
        _y = oy + 1;
        level.setCell(_x, _y, this);
        level.reserve(ox, oy, ReservationKind.Cleared);
        _state = 0x10;
    }

    // Infotron slide commits differ from zonk: the cell-below-destination
    // is marked with a Fall reservation (the C 0x99 semantic), not the
    // Cleared reservation zonks use. This matters because another
    // infotron above can treat that reservation as "this is an infotron
    // about to drop here" and participate in a lockstep slide cascade.
    private void _handleSlideLeft(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);
        if(newState < 0x52)
        {
            _state = newState;
            return;
        }

        // Commit gate: see zonk.d — belowLeft must be strict Space, left
        // must be Space or our own Slide reservation.
        if(!level.isSpace(_x - 1, _y + 1))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }
        if(!level.isSpaceOrReservation(_x - 1, _y, ReservationKind.Slide))
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
        // Infotron slide-commit plants a Fall reservation (0x99 in C) —
        // it's the cue for another infotron above to participate in a
        // lockstep slide cascade. Only plant if the cell is actually
        // Space (don't clobber another mover's reservation).
        if(level.isSpace(_x, _y + 1))
            level.reserve(_x, _y + 1, ReservationKind.Fall);
        _state = 0x22;
    }

    private void _handleSlideRight(Level level)
    {
        auto newState = cast(ubyte)(_state + 1);
        if(newState < 0x62)
        {
            _state = newState;
            return;
        }

        if(!level.isSpace(_x + 1, _y + 1))
        {
            _state = cast(ubyte)(newState - 1);
            return;
        }
        if(!level.isSpaceOrReservation(_x + 1, _y, ReservationKind.Slide))
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
            level.reserve(_x, _y + 1, ReservationKind.Fall);
        _state = 0x32;
    }

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

// Infotron-specific cascade (handleInfotronStateAfterFallingOneTile in
// supaplex.c, ~line 3875). Structurally identical to the zonk cascade,
// but the aboveLeft/aboveRight neighbours must be resting *Infotrons*,
// not zonks. Zonk and infotron cascades never cross-trigger.
void cascadeAfterInfotronFall(Level level, int x, int y)
{
    auto at = level.get(x, y);
    if(at !is null && typeid(at) != typeid(Explosion))
        level.clearCell(x, y);

    if(y <= 0)
        return;
    if(!level.isSpace(x, y - 1))
    {
        if(!level.isSpaceOrReservation(x, y - 1, ReservationKind.Fall))
            return;
        if(y - 2 < 0)
            return;
        auto aboveAbove = level.get(x, y - 2);
        if(aboveAbove is null || cast(Infotron)aboveAbove is null)
            return;
    }

    if(x - 1 >= 0 && y - 1 >= 0)
    {
        auto aboveLeft = cast(Infotron)level.get(x - 1, y - 1);
        if(aboveLeft !is null
            && aboveLeft.state == 0
            && !aboveLeft.moving
            && level.isRestingSlideSupport(x - 1, y))
        {
            aboveLeft.state = 0x60;
            level.reserve(x, y - 1, ReservationKind.Slide);
            return;
        }
    }

    if(x + 1 < 60 && y - 1 >= 0)
    {
        auto aboveRight = cast(Infotron)level.get(x + 1, y - 1);
        if(aboveRight !is null
            && aboveRight.state == 0
            && !aboveRight.moving
            && level.isRestingSlideSupport(x + 1, y))
        {
            aboveRight.state = 0x50;
            level.reserve(x, y - 1, ReservationKind.Slide);
            return;
        }
    }
}
