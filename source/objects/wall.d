module objects.wall;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;

enum Position
{
    None,
    Left,
    Right,
    Top,
    Bottom,
    LeftTop,
    RightTop,
    LeftBottom,
    RightBottom
}

class Wall : GameObject
{
    private Animation _stand;
    private Position _position;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
        _position = Position.None;
        if(x == 0)
        {
            if(y == 0)
                _position = Position.LeftTop;
            else if(y == 23)
                _position = Position.LeftBottom;
            else
                _position = Position.Left;
        }
        else if(x == 59)
        {
            if(y == 0)
                _position = Position.RightTop;
            else if(y == 23)
                _position = Position.RightBottom;
            else
                _position = Position.Right;
        }
        else
        {
            if(y == 0)
                _position = Position.Top;
            else if(y == 23)
                _position = Position.Bottom;
        }
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        if(_position == Position.None)
            _stand.addTile(0, 9);
        else if(_position == Position.Left)
            _stand.addTile(7, 9);
        else if(_position == Position.Right)
            _stand.addTile(8, 9);
        else if(_position == Position.Top)
            _stand.addTile(2, 9);
        else if(_position == Position.Bottom)
            _stand.addTile(5, 9);
        else if(_position == Position.LeftTop)
            _stand.addTile(1, 9);
        else if(_position == Position.RightTop)
            _stand.addTile(3, 9);
        else if(_position == Position.LeftBottom)
            _stand.addTile(4, 9);
        else if(_position == Position.RightBottom)
            _stand.addTile(6, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
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

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}
