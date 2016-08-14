module objects.murphy;

import std.stdio;
import std.conv;
import dsfml.graphics;
import level;
import gameobject;
import animation;
import utils;

class Murphy : GameObject
{
    private Animation _stand;
    private Animation _left;
    private Animation _right;
    private Animation _leftPush;
    private Animation _rightPush;
    private Vector2f _center;
    private bool _dead;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    @property
    {
        public bool dead()
        {
            return _dead;
        }

        public void dead(bool value)
        {
            _dead = value;
        }
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 0);
        _left = new Animation();
        _left.setSpriteSheet(_texture);
        _left.addTile(2, 1);
        _left.addTile(1, 1);
        _left.addTile(0, 1);
        _right = new Animation();
        _right.setSpriteSheet(_texture);
        _right.addTile(3, 1);
        _right.addTile(4, 1);
        _right.addTile(5, 1);
        _leftPush = new Animation();
        _leftPush.setSpriteSheet(_texture);
        _leftPush.addTile(11, 1);
        _leftPush.addTile(11, 1);
        _leftPush.addTile(11, 1);
        _rightPush = new Animation();
        _rightPush.setSpriteSheet(_texture);
        _rightPush.addTile(12, 1);
        _rightPush.addTile(12, 1);
        _rightPush.addTile(12, 1);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.setBlendMode(BlendMode.None);
        _sprite.play(_stand, null);
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
    }

    public void setPushAnimation(MoveDirection direction)
    {
        if(direction == MoveDirection.Left)
            _currentAnimation = _leftPush;
        else if(direction == MoveDirection.Right)
            _currentAnimation = _rightPush;
    }

    public override void stop()
    {
        _currentAnimation = _stand;
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

    public override void update(Duration time)
    {
        _sprite.update(time);
        auto center = _sprite.getGlobalBounds.getCenter;
        if(center.x != _center.x || center.y != _center.y)
        {
            View view = _window.view.dup;
            auto viewXL = center.x - view.size.x / 2;
            auto viewYL = center.y - view.size.y / 2;
            auto viewXR = center.x + view.size.x / 2;
            auto viewYR = center.y + view.size.y / 2;
            if(viewXL < 16 || viewXR > 60 * 32 - 16)
                center.x = view.center.x;
            if(viewYL < 16 || viewYR > 24 * 32 - 16)
                center.y = view.center.y;
            view.center = center;
            _window.view = view;
            _center = center;
        }
        if(_moving || _dead)
            return;
        if(Keyboard.isKeyPressed(Keyboard.Key.Up))
        {
            _currentAnimation = _left;
            _level.move(this, MoveDirection.Up);
        }
        else if(Keyboard.isKeyPressed(Keyboard.Key.Down))
        {
            _currentAnimation = _left;
            _level.move(this, MoveDirection.Down);
        }
        else if(Keyboard.isKeyPressed(Keyboard.Key.Left))
        {
            _currentAnimation = _left;
            _level.move(this, MoveDirection.Left);
        }
        else if(Keyboard.isKeyPressed(Keyboard.Key.Right))
        {
            _currentAnimation = _right;
            _level.move(this, MoveDirection.Right);
        }
        else
        {
            _direction = MoveDirection.None;
            _currentAnimation = _stand;
        }
    }

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}

