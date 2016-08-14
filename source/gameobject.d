module gameobject;

import dsfml.graphics;
import animation;
import level;
public import objects.murphy;

enum MoveDirection
{
    None,
    Left,
    Right,
    Up,
    Down
}

enum MoveCheckResult
{
    False,
    True,
    Push
}

abstract class GameObject
{
    protected RenderWindow _window;
    protected Texture _texture;
    protected AnimatedSprite _sprite;
    protected Animation _currentAnimation;
    protected Animation _decayAnimation;
    protected MoveDirection _direction;
    protected Level _level;
    protected int _x;
    protected int _y;
    protected int _oldX;
    protected int _oldY;
    protected shared bool _moving;
    protected bool _fall;
    protected bool _pushed;

    this(RenderWindow window, Texture texture, int x, int y)
    {
        _window = window;
        _texture = texture;
        _x = x;
        _y = y;
    }

    public abstract void load(Level level);
    public abstract MoveCheckResult push(Murphy player, MoveDirection direction);
    public abstract void stop();
    public abstract void draw();
    public abstract void update(Duration time);
    public abstract void updateMove();
    public abstract void updateMove2();

    @property
    {
        public MoveDirection direction()
        {
            return _direction;
        }

        public void direction(MoveDirection direction)
        {
            _direction = direction;
        }
    }

    @property
    {
        public int x()
        {
            return _x;
        }

        public void x(int x)
        {
            _x = x;
        }
    }

    @property
    {
        public int y()
        {
            return _y;
        }

        public void y(int y)
        {
            _y = y;
        }
    }

    @property
    {
        public int oldX()
        {
            return _oldX;
        }

        public void oldX(int x)
        {
            _oldX = x;
        }
    }

    @property
    {
        public int oldY()
        {
            return _oldY;
        }

        public void oldY(int y)
        {
            _oldY = y;
        }
    }

    @property
    {
        public bool moving()
        {
            return _moving;
        }

        public void moving(bool moving)
        {
            _moving = moving;
        }
    }

    @property
    {
        public bool fall()
        {
            return _fall;
        }

        public void fall(bool fall)
        {
            _fall = fall;
        }
    }

    @property
    {
        public bool pushed()
        {
            return _pushed;
        }

        public void pushed(bool pushed)
        {
            _pushed = pushed;
        }
    }

    @property public AnimatedSprite sprite()
    {
        return _sprite;
    }

    @property public Animation decayAnimation()
    {
        return _decayAnimation;
    }

    @property
    {
        public Animation currentAnimation()
        {
            return _currentAnimation;
        }

        public void currentAnimation(Animation animation)
        {
            this._currentAnimation = animation;
        }
    }

    public void finishMove()
    {
        _level.finishMove(this);
    }
}

