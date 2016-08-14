module objects.enemies;

import dsfml.graphics;
import gameobject;
import animation;
import level;
import utils;

class SnikSnak : GameObject
{
    private Animation _stand;
    private Animation _turn;
    private Animation _left;
    private Animation _right;
    private Animation _up;
    private Animation _down;

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
        _sprite = new AnimatedSprite(dur!"msecs"(300), true, false);
        _sprite.play(_turn, null);
    }

    public override void draw()
    {
        _sprite.play(_currentAnimation, null);
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
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

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
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