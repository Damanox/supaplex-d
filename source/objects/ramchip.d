module objects.ramchip;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;
import interfaces;

class RamChipBase : GameObject
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

class RamChip : RamChipBase, ISlideable
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
        _stand.addTile(16, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class RamChipLeft : RamChipBase
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
        _stand.addTile(14, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class RamChipRight : RamChipBase
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
        _stand.addTile(15, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class RamChipTop : RamChipBase
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
        _stand.addTile(13, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

class RamChipBottom : RamChipBase
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
        _stand.addTile(12, 9);
        _currentAnimation = _stand;
        _sprite = new AnimatedSprite(dur!"msecs"(0), true, false);
    }
}

