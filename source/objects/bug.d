module objects.bug;

import std.random;
import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;

// Bug (tile 25). The Bug has two phases, encoded in its `_state` byte:
//   * Active: state 0..0x0D. Lethal on Murphy contact. The state counter
//     advances once every 4 sim ticks (original gates on `gFrameCounter & 3`).
//     When it reaches 0x0E, roll a dormant delay.
//   * Dormant: state 0x80..0xFF (signed-byte negative). Counts up every
//     4 ticks until it rolls over to 0, at which point the Bug becomes
//     active again. Murphy can walk onto a dormant Bug — Level.checkMove
//     converts it to a Base in that case and falls through to the normal
//     consumable eat-path.
class Bug : GameObject
{
    private Animation _stand;
    private int _subTick;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(1, 10);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
        // Starts active at state 0 — matches a fresh Bug tile in the
        // level data (no sub-state encoded on-disk).
        _state = 0;
    }

    public override void draw()
    {
        _sprite.play(_currentAnimation, null);
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
    }

    public override void stop()
    {}

    public override void update(Duration time)
    {}

    public override void updateState(Level level)
    {
        // Gate: C runs the Bug state machine only every 4th gFrameCounter
        // tick. We reproduce with a per-bug counter — every 4 sim ticks
        // advance the state byte once.
        _subTick++;
        if((_subTick & 3) != 0)
            return;

        byte frame = cast(byte)_state;
        frame++;
        if(frame >= 0x0E)
        {
            // Roll a dormant delay. C: `-((rand & 0x3F) + 0x20)` gives
            // signed range [-0x5F, -0x20], i.e. uint8 [0xA1, 0xE0] which
            // then counts up every 4 ticks through 0xFF and wraps to 0
            // (reactivating).
            immutable int r = uniform(0, 0x40) + 0x20;
            frame = cast(byte)(-r);
        }
        _state = cast(ubyte)frame;
        // When frame < 0 (state high-bit set) the Bug is dormant —
        // nothing else to do this tick. Active phase has no additional
        // behaviour here; Murphy-contact detonation is handled in
        // Level.checkMove, not from the Bug's own tick.
    }

    // True when the Bug is in its active (dangerous) phase. Port of the
    // `state < 0x80` check in C supaplex.c:10320.
    public bool isActive() const
    {
        return _state < 0x80;
    }
}