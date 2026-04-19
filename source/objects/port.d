module objects.port;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;

class Port : GameObject
{
    private Animation _stand;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
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
}

class PortLeft : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(5, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class PortRight : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(4, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class PortUp : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(6, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class PortDown : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(3, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class Port2WayVert : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(0, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class Port2WayHoriz : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(1, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class Port4Way : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(2, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class GravityPortLeft : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(5, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class GravityPortRight : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(4, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class GravityPortUp : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(6, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class GravityPortDown : Port
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _stand = new Animation();
        _stand.setSpriteSheet(_texture);
        _stand.addTile(3, 13);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}