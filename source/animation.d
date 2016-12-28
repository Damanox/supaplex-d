module animation;

import dsfml.graphics;
import gameobject;

class Animation
{
    private IntRect[] _frames;
    private Texture _texture;
    private string _name;

    this()
    {
        _texture = null;
    }

    this(string name)
    {
        _texture = null;
        _name = name;
    }

    void addFrame(IntRect rect)
    {
        _frames ~= rect;
    }

    void setSpriteSheet(Texture texture)
    {
        _texture = texture;
    }

    Texture getSpriteSheet()
    {
        return _texture;
    }

    size_t getSize() const
    {
        return _frames.length;
    }

    const IntRect getFrame(size_t n)
    {
        return _frames[n];
    }

    string getName() const
    {
        return _name;
    }
}

class AnimatedSprite : Drawable, Transformable
{
    mixin NormalTransformable;

    private
    {
        Animation m_animation;
        Duration m_frameTime;
        Duration m_currentTime;
        size_t m_currentFrame;
        bool m_isPaused;
        bool m_isLooped;
        Texture m_texture;
        Vertex[4] m_vertices;
        BlendMode m_blendMode;
        void delegate() m_stopDelegate;
    }

    this(Duration frameTime, bool paused, bool looped)
    {
        m_animation = null;
        m_frameTime = frameTime;
        m_currentFrame = 0;
        m_isPaused = paused;
        m_isLooped = looped;
        m_texture = null;
        m_blendMode = BlendMode.Alpha;
    }

    void setAnimation(Animation animation)
    {
        m_animation = animation;
        m_texture = m_animation.getSpriteSheet();
        m_currentFrame = 0;
        setFrame(m_currentFrame);
    }

    void setBlendMode(BlendMode mode)
    {
        m_blendMode = mode;
    }

    void setFrameTime(Duration time)
    {
        m_frameTime = time;
    }

    void play()
    {
        m_isPaused = false;
    }

    void play(Animation animation, void delegate() stop)
    {
        m_stopDelegate = stop;
        if(getAnimation() != animation)
            setAnimation(animation);
        play();
    }

    void pause()
    {
        m_isPaused = true;
    }

    void stop()
    {
        m_isPaused = true;
        m_currentFrame = 0;
        setFrame(m_currentFrame);
    }

    void setLooped(bool looped)
    {
        m_isLooped = looped;
    }

    void setColor(const Color color)
    {
        // Update the vertices' color
        m_vertices[0].color = color;
        m_vertices[1].color = color;
        m_vertices[2].color = color;
        m_vertices[3].color = color;
    }

    Animation getAnimation()
    {
        return m_animation;
    }

    FloatRect getLocalBounds() const
    {
        IntRect rect = m_animation.getFrame(m_currentFrame);

        float width = (abs(rect.width));
        float height = (abs(rect.height));

        return FloatRect(0, 0, width, height);
    }

    FloatRect getGlobalBounds()
    {
        return getTransform().transformRect(getLocalBounds());
    }

    bool isLooped() const
    {
        return m_isLooped;
    }

    bool isPlaying() const
    {
        return !m_isPaused;
    }

    Duration getFrameTime() const
    {
        return m_frameTime;
    }

    Duration getCurrentTime() const
    {
        return m_currentTime;
    }

    Duration getLeftTime() const
    {
        if(m_isPaused)
            return Duration.zero;
        auto res = m_frameTime * m_animation.getSize() - (m_frameTime * m_currentFrame + m_currentTime);
        return res.total!"msecs" >= 0 ? res : Duration.zero;
    }

    void setFrame(size_t newFrame, bool resetTime = true)
    {
        if(m_animation)
        {
            //calculate new vertex positions and texture coordiantes
            IntRect rect = m_animation.getFrame(newFrame);

            m_vertices[0].position = Vector2f(0f, 0f);
            m_vertices[1].position = Vector2f(0f, (rect.height));
            m_vertices[2].position = Vector2f((rect.width), (rect.height));
            m_vertices[3].position = Vector2f((rect.width), 0f);

            float left = (rect.left) + 0.0001f;
            float right = left + (rect.width);
            float top = (rect.top);
            float bottom = top + (rect.height);

            m_vertices[0].texCoords = Vector2f(left, top);
            m_vertices[1].texCoords = Vector2f(left, bottom);
            m_vertices[2].texCoords = Vector2f(right, bottom);
            m_vertices[3].texCoords = Vector2f(right, top);
        }

        if(resetTime)
            m_currentTime = Duration.zero;
    }

    void update(Duration deltaTime)
    {
        // if not paused and we have a valid animation
        if(!m_isPaused && m_animation)
        {
            // add delta time
            m_currentTime += deltaTime;
            // if current time is bigger then the frame time advance one frame
            if(m_currentTime >= m_frameTime)
            {
                // reset time, but keep the remainder
                m_currentTime = m_currentTime % m_frameTime;
                // get next Frame index
                if(m_currentFrame + 1 < m_animation.getSize())
                    m_currentFrame++;
                else
                {
                    // animation has ended
                    m_currentFrame = 0; // reset to start
                    if(!m_isLooped)
                        m_isPaused = true;

                    if(m_stopDelegate !is null)
                    {
                        m_stopDelegate();
                        m_stopDelegate = null;
                    }
                }

                // set the current frame, not reseting the time
                setFrame(m_currentFrame, false);
            }
        }
    }

    override void draw(RenderTarget target, RenderStates states)
    {
        if(m_animation && m_texture)
        {
            states.transform *= getTransform();
            states.texture = m_texture;
            states.blendMode = m_blendMode;
            target.draw(m_vertices, PrimitiveType.Quads, states);
        }
    }
}

