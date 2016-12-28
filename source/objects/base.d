module objects.base;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import interfaces;

class Base : GameObject, IConsumable
{
    private Animation _stand;
    private Animation _disappear;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 10);
        _disappear = new Animation();
        _disappear.setSpriteSheet(_texture);
        _disappear.addTile(6, 10);
        _disappear.addTile(7, 10);
        _disappear.addTile(8, 10);
        _disappear.addTile(9, 10);
        _disappear.addTile(10, 10);
        _disappear.addTile(11, 10);
        _disappear.addTile(12, 10);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(50), true, false);
        _sprite.play(_stand, null);
    }

    public override void startDisappear()
    {
        _currentAnimation = _disappear;
        _sprite.play(_disappear, &stopDisappear);
    }

    public override void stopDisappear()
    {
        _level.destroy(x, y);
    }

    public override void draw()
    {
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
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
    {}

    public override void updateMove2()
    {}
}

