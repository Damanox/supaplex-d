module objects.explosion;

import dsfml.graphics;
import gameobject;
import level;
import animation;
import utils;

class Explosion : GameObject
{
    private Animation _explode;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {
        _level = level;
        _explode = new Animation();
        _explode.setSpriteSheet(_texture);
        _explode.addTile(0, 5);
        _explode.addTile(1, 5);
        _explode.addTile(2, 5);
        _explode.addTile(3, 5);
        _explode.addTile(4, 5);
        _explode.addTile(5, 5);
        _explode.addTile(6, 5);
        _currentAnimation = _explode;
        _sprite = new AnimatedSprite(dur!"msecs"(100), true, false);
        _sprite.setBlendMode(BlendMode.None);
        _sprite.play(_explode, &destroy);
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
    }

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
    }

    public override void stop()
    {}

    private void destroy()
    {
        _level.destroy(x, y);
    }

    public override void draw()
    {
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
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
