module utils;

import dsfml.graphics;
import animation;

Vector2f getCenter(FloatRect rect)
{
    return Vector2f(rect.left + rect.width / 2, rect.top + rect.height / 2);
}

void addTile(Animation animation, int x, int y)
{
    animation.addFrame(IntRect(x * 32, y * 32, 32, 32));
}