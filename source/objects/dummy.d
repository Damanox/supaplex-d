module objects.dummy;

import dsfml.graphics;
import gameobject;
import level;

class Dummy : GameObject
{
    this(RenderWindow window, Texture texture, int x, int y)
    {
        super(window, texture, x, y);
    }

    public override void load(Level level)
    {}

    public override MoveCheckResult push(Murphy player, MoveDirection direction)
    {
        return MoveCheckResult.False;
    }

    public override void stop()
    {}

    public override void draw()
    {}

    public override void update(Duration time)
    {}

    public override void updateMove()
    {}

    public override void updateMove2()
    {}
}

