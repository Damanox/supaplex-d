module objects.zonk;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import objects.infotron;
import objects.murphy;

class Zonk : GameObject
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

    public override void stop()
    {
        _currentAnimation = _stand;
        _sprite.play(_stand, null);
    }

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
            _currentAnimation = _down;
            _fall = true;
            _pushed = false;
            _level.move(this, MoveDirection.Down);
        }
        else if(_fall)
        {
            _fall = false;
            auto object = _level.get(x, y + 1);
            if(typeid(object) == typeid(Murphy) && !object.moving)
                _level.explode(object.x, object.y);
        }
    }

    public override void updateMove2()
    {
        if(_moving)
            return;
        if(_level.check(x - 1, y + 1))
        {
            auto object = _level.get(x, y + 1);
            if(!object.moving && (typeid(object) == typeid(Zonk) || typeid(object) == typeid(Infotron)))
            {
                _currentAnimation = _left;
                _level.move(this, MoveDirection.Left);
            }
        }
        else if(_level.check(x + 1, y + 1))
        {
            auto object = _level.get(x, y + 1);
            if(!object.moving && (typeid(object) == typeid(Zonk) || typeid(object) == typeid(Infotron)))
            {
                _currentAnimation = _right;
                _level.move(this, MoveDirection.Right);
            }
        }
    }
}