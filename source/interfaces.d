module interfaces;

import gameobject;

public interface IPushable
{
    MoveCheckResult push(Murphy player, MoveDirection direction);
}

public interface IExplosive
{
    //void explode();
}

public interface IConsumable
{
    void startDisappear();
    void stopDisappear();
}

public interface IUseable
{
    void use();
}

public interface ISlideable {}

public interface INonDestructible {}