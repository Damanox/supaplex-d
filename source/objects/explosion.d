module objects.explosion;

import dsfml.graphics;
import gameobject;
import level;
import animation;
import utils;

class Explosion : GameObject
{
    private Animation _explode;
    // Sim-tick counter driving the explosion's lifetime. Starts at -1
    // so the first updateState call (which pre-increments) sees
    // _simTick == 0 — matching c_sim's gFrameCounter starting at 0
    // before the first updateMovingObjects pass. This keeps the
    // "advance every 4th tick" decay aligned between the two sims.
    private int _simTick = -1;

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
        // Sprite plays for visuals only (looping); we no longer fire a
        // stop-delegate-based destroy.
        _sprite.play(_explode, null);
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
    }

    public override void stop()
    {}

    public override void draw()
    {
        _sprite.position = Vector2f(_x * 32f, _y * 32f);
        _window.draw(_sprite);
    }

    public override void update(Duration time)
    {
        _sprite.update(time);
    }

    // Sim-tick driven decay: every 4th tick advance one of 8 states;
    // at state 8 the cell clears. Matches c_sim.updateExplosionTiles.
    public override void updateState(Level level)
    {
        _simTick++;
        if((_simTick & 3) != 0)
            return;
        _state++;
        if(_state == 8)
            level.destroy(x, y);
    }
}
