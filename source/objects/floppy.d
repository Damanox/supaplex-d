module objects.floppy;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import objects.dummy;

class FloppyOrange : GameObject
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

    public override void updateMove()
    {
        if(_moving)
            return;
        if(_level.check(x, y + 1))
        {
            _sprite.setFrameTime(dur!"msecs"(100));
            _fall = true;
            _pushed = false;
            _level.move(this, MoveDirection.Down);
        }
        else if(_fall)
        {
            _fall = false;
            auto object = _level.get(x, y + 1);
            if(object !is null && typeid(object) != typeid(Dummy) && !object.moving)
                _level.explode(x, y);
        }
    }

    public override void updateMove2()
    {}
}

class FloppyYellow : GameObject
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

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}


class FloppyRed : GameObject
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
        _stand.addTile(2, 12);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
    }

    public override void draw()
    {
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
    }

    public override void stop()
    {}

    public override void update(Duration time)
    {}

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}
