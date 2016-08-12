import std.stdio;
import std.file;
import std.conv;
import dsfml.graphics;
import dsfml.system;
import level;

void main(string[] args)
{
    auto window = new RenderWindow(VideoMode(800,600),"Supaplex-D");
    window.setFramerateLimit(120);
    window.view = new View(FloatRect(0, 0, 800/1.5f, 600/1.5f));

    auto levels = cast(LevelData[])read("./LEVELS.DAT");

    auto level = new Level(800, 600);
    level.build(window, levels[0]);

    auto clock = new Clock();
    Duration time;

    while(window.isOpen())
    {
        Event event;

        while(window.pollEvent(event))
        {
            if(event.type == event.EventType.Closed)
            {
                window.close();
            }
            if(event.type == event.EventType.Resized)
            {
                auto view = window.view.dup;
                view.size = Vector2f(event.size.width / 1.5f, event.size.height / 1.5f);
                window.view = view;
                level.centerView(window);
            }
        }

        window.clear();

        time = clock.getElapsedTime();
        clock.restart();
        level.update(time);
        level.draw();

        window.display();
    }
}