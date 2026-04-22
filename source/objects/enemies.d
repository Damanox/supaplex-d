module objects.enemies;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import interfaces;

class SnikSnak : GameObject, IExplosive
{
    private Animation _stand;
    private Animation _turn;
    private Animation _left;
    private Animation _right;
    private Animation _up;
    private Animation _down;

    // Desired direction for the next move attempt. Persisted across ticks
    // (unlike _direction, which Level.finishMove clears to None when the
    // animated move completes). Starts Left per the original's spawn
    // behaviour; on block, rotates clockwise and retries within the same
    // tick until a free cell is found or all 4 directions are blocked.
    private MoveDirection _wantDir = MoveDirection.Left;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(7, 2);
        _left = new Animation();
        _left.setSpriteSheet(_texture);
        _left.addTile(4, 3);
        _left.addTile(5, 3);
        _left.addTile(6, 3);
        _left.addTile(7, 3);
        _left.addTile(8, 3);
        _left.addTile(9, 3);
        _left.addTile(10, 3);
        _right = new Animation();
        _right.setSpriteSheet(_texture);
        _right.addTile(12, 3);
        _right.addTile(13, 3);
        _right.addTile(14, 3);
        _right.addTile(15, 3);
        _right.addTile(16, 3);
        _right.addTile(17, 3);
        _right.addTile(18, 3);
        _up = new Animation();
        _up.setSpriteSheet(_texture);
        _up.addTile(10, 2);
        _up.addTile(11, 2);
        _up.addTile(12, 2);
        _up.addTile(13, 2);
        _up.addTile(14, 2);
        _up.addTile(15, 2);
        _down = new Animation();
        _down.setSpriteSheet(_texture);
        _down.addTile(18, 2);
        _down.addTile(19, 2);
        _down.addTile(0, 3);
        _down.addTile(1, 3);
        _down.addTile(2, 3);
        _down.addTile(3, 3);
        _turn = new Animation();
        _turn.setSpriteSheet(_texture);
        _turn.addTile(0, 2);
        _turn.addTile(1, 2);
        _turn.addTile(2, 2);
        _turn.addTile(3, 2);
        _turn.addTile(4, 2);
        _turn.addTile(5, 2);
        _turn.addTile(6, 2);
        _turn.addTile(7, 2);
        _currentAnimation = _turn;
        // 8 frames × 30 ms ≈ 240 ms per cell, close to Supaplex's original
        // ~8-tick (≈228 ms) SnikSnak step cadence.
        _sprite = new AnimatedSprite(dur!"msecs"(30), true, false);
        _sprite.play(_turn, null);
    }

    public override void draw()
    {
        // During an animated move, interpolate the sub-tile visual from the
        // sprite's remaining animation time — same pattern as Murphy /
        // FloppyOrange. Outside a move, draw at the logical cell.
        if(_moving && _direction != MoveDirection.None)
        {
            auto animTime = _sprite.getFrameTime() * _sprite.getAnimation.getSize();
            auto leftMs = _sprite.getLeftTime().total!"msecs";
            auto totalMs = animTime.total!"msecs";
            if(totalMs <= 0)
                totalMs = 1;
            final switch(_direction) with(MoveDirection)
            {
                case Left:
                    _sprite.position = Vector2f(_x * 32f + leftMs * 32f / totalMs, _y * 32f);
                    break;
                case Right:
                    _sprite.position = Vector2f(_x * 32f - leftMs * 32f / totalMs, _y * 32f);
                    break;
                case Up:
                    _sprite.position = Vector2f(_x * 32f, _y * 32f + leftMs * 32f / totalMs);
                    break;
                case Down:
                    _sprite.position = Vector2f(_x * 32f, _y * 32f - leftMs * 32f / totalMs);
                    break;
                case None:
                    _sprite.position = Vector2f(_x * 32f, _y * 32f);
                    break;
            }
        }
        else
        {
            _sprite.position = Vector2f(_x * 32f, _y * 32f);
        }
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
        // Mid-move: the animation's stop delegate (Level.finishMove) will
        // clear _moving when the sprite finishes the 8-frame cycle. Skip.
        if(_moving)
            return;

        auto d = _wantDir == MoveDirection.None ? MoveDirection.Left : _wantDir;
        foreach(_; 0 .. 4)
        {
            int tx = _x;
            int ty = _y;
            auto animation = _turn;
            final switch(d) with(MoveDirection)
            {
                case Left:
                    tx--;
                    animation = _left;
                    break;
                case Right:
                    animation = _right;
                    tx++;
                    break;
                case Up:
                    animation = _up;
                    ty--;
                    break;
                case Down:
                    animation = _down;
                    ty++;
                    break;
                case None:  break;
            }
            // Accept only fully empty cells. level.check returns true only
            // when the target is null — reservations, objects, and OOB
            // coordinates all block the SnikSnak here.
            if(level.check(tx, ty))
            {
                _wantDir = d;
                _currentAnimation = animation;
                level.move(this, d);
                return;
            }
            d = _rotateCW(d);
        }
        // All four directions blocked: stay put, keep _wantDir unchanged
        // so next tick we retry in the same rotational order.
    }

    // Clockwise rotation of a cardinal direction in screen-space
    // (Y grows downward): Left → Up → Right → Down → Left.
    private static MoveDirection _rotateCW(MoveDirection d)
    {
        final switch(d) with(MoveDirection)
        {
            case Left:  return Up;
            case Up:    return Right;
            case Right: return Down;
            case Down:  return Left;
            case None:  return Left;
        }
    }
}

class Electron : GameObject
{
    private Animation _stand;
    private Animation _move;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 4);
        _move = new Animation();
        _move.setSpriteSheet(_texture);
        _move.addTile(0, 4);
        _move.addTile(1, 4);
        _move.addTile(2, 4);
        _move.addTile(3, 4);
        _move.addTile(4, 4);
        _move.addTile(5, 4);
        _move.addTile(6, 4);
        _move.addTile(7, 4);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.play(_stand, null);
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
    {
        _sprite.update(time);
    }
}