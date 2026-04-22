module objects.floppy;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import interfaces;
import objects.reservation;

class FloppyOrange : GameObject, IPushable, IExplosive
{
    private Animation _stand;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 12);
        _stand.addTile(0, 12);
        _stand.addTile(0, 12);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
    }

    public override void draw()
    {
        auto animTime = _sprite.getFrameTime() * _sprite.getAnimation.getSize();
        if(_direction == MoveDirection.None)
            _sprite.position = Vector2f(_x * 32f, _y * 32f);
        else if(_direction == MoveDirection.Up)
            _sprite.position = Vector2f(_x * 32f, _y * 32f + _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs");
        else if(_direction == MoveDirection.Down)
            _sprite.position = Vector2f(_x * 32f, _y * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs");
        else if(_direction == MoveDirection.Left)
            _sprite.position = Vector2f(_x * 32f + _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
        else if(_direction == MoveDirection.Right)
            _sprite.position = Vector2f(_x * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
        _window.draw(_sprite);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        auto res = MoveCheckResult.False;
        if(_level.check(x, y + 1))
            return res;
        if(direction == MoveDirection.Left && _level.checkMove(x - 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        else if(direction == MoveDirection.Right && _level.checkMove(x + 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        if(res != MoveCheckResult.Push)
            return res;
        _pushed = true;
        _level.move(this, direction);
        player.setPushAnimation(direction);
        return res;
    }

    public override void stop()
    {}

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

    public override void updateState(Level level)
    {
        if(_moving)
            return;
        if(level.check(x, y + 1))
        {
            _sprite.setFrameTime(dur!"msecs"(100));
            _fall = true;
            _pushed = false;
            level.move(this, MoveDirection.Down);
        }
        else if(_fall)
        {
            _fall = false;
            auto object = level.get(x, y + 1);
            if(object !is null && cast(Reservation)object is null)
            {
                // IExplosive targets (e.g. SnikSnak) detonate on contact
                // even if they're mid-move — the explosion replaces the
                // enemy in the grid via Level.explode. For non-IExplosive
                // tiles keep the old guard so a floppy doesn't detonate
                // against an object that's animating out of this cell.
                if(cast(IExplosive)object !is null || !object.moving)
                    level.explode(x, y);
            }
        }
    }
}

class FloppyYellow : GameObject, IPushable, IExplosive
{
    private Animation _stand;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(1, 12);
        _stand.addTile(1, 12);
        _stand.addTile(1, 12);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
    }

    public override void draw()
    {
        auto animTime = _sprite.getFrameTime() * _sprite.getAnimation.getSize();
        if(_direction == MoveDirection.None)
            _sprite.position = Vector2f(_x * 32f, _y * 32f);
        else if(_direction == MoveDirection.Up)
            _sprite.position = Vector2f(_x * 32f, _y * 32f + _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs");
        else if(_direction == MoveDirection.Down)
            _sprite.position = Vector2f(_x * 32f, _y * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs");
        else if(_direction == MoveDirection.Left)
            _sprite.position = Vector2f(_x * 32f + _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
        else if(_direction == MoveDirection.Right)
            _sprite.position = Vector2f(_x * 32f - _sprite.getLeftTime().total!"msecs" * 32f / animTime.total!"msecs", _y * 32f);
        _window.draw(_sprite);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        auto res = MoveCheckResult.False;
        if(direction == MoveDirection.Left && _level.checkMove(x - 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        else if(direction == MoveDirection.Right && _level.checkMove(x + 1, y, this, direction) == MoveCheckResult.True)
            res = MoveCheckResult.Push;
        if(res != MoveCheckResult.Push)
            return res;
        _pushed = true;
        _level.move(this, direction);
        player.setPushAnimation(direction);
        return res;
    }

    public override void stop()
    {}

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

}


// Two phases, encoded in `_state`:
//   * Dormant (state == 0): sits on the level, pickup-able by Murphy via
//     the IConsumable path. Does nothing on its own.
//   * Planted/counting (state 1..0x27): set by Murphy.plant(). Ticks +1
//     every sim tick; at 0x28 (40 ticks ≈ 1.1 s at 35 Hz) detonates a
//     3×3 explosion at its cell.
class FloppyRed : GameObject, IConsumable
{
    private Animation _stand;
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
        _stand.addTile(2, 12);
        _disappear = new Animation();
        _disappear.setSpriteSheet(_texture);
        _disappear.addTile(2, 12);
        _disappear.addTile(3, 12);
        _disappear.addTile(4, 12);
        _disappear.addTile(5, 12);
        _disappear.addTile(6, 12);
        _disappear.addTile(7, 12);
        _disappear.addTile(8, 12);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
        _state = 0;
    }

    public override void startDisappear()
    {
        _disappearing = true;
        _currentAnimation = _disappear;
        _sprite.play(_disappear, &stopDisappear);
    }

    public override void stopDisappear()
    {
        _disappearing = false;
        _level.destroy(x, y);
    }

    public override void draw()
    {
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
    }

    public override void stop()
    {}

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

    public override void updateState(Level level)
    {
        // Dormant: unplanted red disk just sits on the level.
        if(_state == 0)
            return;

        // Planted countdown. increment state byte every sim tick since
        // each planted disk is its own object here.
        _state++;
        if(_state >= 0x28)
        {
            level.explode(_x, _y);
        }
    }

    // Called by Murphy.plant() to arm the countdown. Cell placement is
    // handled by the caller (Level.setCell etc.); we just flip state.
    public void arm()
    {
        _state = 1;
    }
}
