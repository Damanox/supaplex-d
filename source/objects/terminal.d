module objects.terminal;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import std.stdio;

class Terminal : GameObject
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
        _stand.addTile(0, 11);
        _stand.addTile(1, 11);
        _stand.addTile(2, 11);
        _stand.addTile(3, 11);
        _stand.addTile(4, 11);
        _stand.addTile(5, 11);
        _stand.addTile(6, 11);
        _stand.addTile(7, 11);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(300), true, true);
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

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}