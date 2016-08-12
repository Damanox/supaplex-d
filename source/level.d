module level;

import std.stdio;
import std.parallelism;
import std.conv;
import dsfml.graphics;
import gameobject;
import utils;
import objects.wall;
import objects.base;
import objects.murphy;
import objects.infotron;
import objects.ramchip;
import objects.bug;
import objects.zonk;
import objects.exit;
import objects.floppy;
import objects.port;
import objects.terminal;
import objects.hardware;
import objects.enemies;
import objects.dummy;
import objects.explosion;

struct LevelPort
{
    byte hi; //(2*(x+y*60)) div 256 (integer division) where (x,y) are the coordinates of the special port (0,0=left top)
    byte lo; //(2*(x+y*60)) mod 256 (remainder of division) where (x,y) are the coordinates of the special port (0,0=left top)
    byte gravity; //1 (turn on) or 0 (turn off) gravity
    byte fr_zonks; //2 (turn on) or 0 (turn off) freeze zonks
    byte fr_enemy; //1 (turn on) or 0 (turn off) freeze enemies
    byte unused;
};

struct LevelData
{
    byte[1440] map;
    short unused;
    short unused2;
    byte gravitation;//Gravitation start value (0=off, 1=on)
    byte ver;//20h + SpeedFix_version_hex: v5.4 => 74h; v6.0 => 80h. In the original Supaplex, this value is just 20h.
    char[23] name;
    byte freeze;//Freeze zonks start value (0=off, 2=on) (yes 2=on, no mistake!)
    byte goal;//Number of infotrons needed. 0 means Supaplex will count the total number of infotrons in the level at the start and use that.
    byte switches;//Number of gravity switch ports (maximum 10!)
    LevelPort[10] ports;
    int unused3;
};

class Level
{
    private float _width;
    private float _height;
    private GameObject[][] _map;
    private Murphy _murphy;
    private RenderWindow _window;
    private Texture _tiles;

    this(float width, float height)
    {
        _width = width;
        _height = height;
    }

    public void build(RenderWindow window, LevelData data)
    {
        _window = window;
        _map = new GameObject[][](60,24);
        auto img = new Image();
        if(!img.loadFromFile("tiles.png"))
            return;
        _tiles = new Texture();
        if(!_tiles.loadFromImage(img))
            return;
        _tiles.setSmooth(false);
        for(auto y = 0; y < 24; y++)
        {
            for(auto x = 0; x < 60; x++)
            {
                if(data.map[x + y * 60] == 1)
                    _map[x][y] = new Zonk(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 2)
                    _map[x][y] = new Base(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 3)
                {
                    _murphy = new Murphy(window, _tiles, x, y);
                    _map[x][y] = _murphy;
                }
                else if(data.map[x + y * 60] == 4)
                    _map[x][y] = new Infotron(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 5)
                    _map[x][y] = new RamChip(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 6)
                    _map[x][y] = new Wall(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 7)
                    _map[x][y] = new Exit(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 8)
                    _map[x][y] = new FloppyOrange(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 9)
                    _map[x][y] = new PortRight(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 10)
                    _map[x][y] = new PortDown(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 11)
                    _map[x][y] = new PortLeft(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 12)
                    _map[x][y] = new PortUp(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 13)
                    _map[x][y] = new GravityPortRight(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 14)
                    _map[x][y] = new GravityPortDown(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 15)
                    _map[x][y] = new GravityPortLeft(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 16)
                    _map[x][y] = new GravityPortUp(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 17)
                    _map[x][y] = new SnikSnak(window, _tiles, x, y); //Enemy that follows the left edge in it's moving direction.
                else if(data.map[x + y * 60] == 18)
                    _map[x][y] = new FloppyYellow(window, _tiles, x, y); // Explodes when player touches a terminal.
                else if(data.map[x + y * 60] == 19)
                    _map[x][y] = new Terminal(window, _tiles, x, y); // Touching it causes yellow floppies to explode.
                else if(data.map[x + y * 60] == 20)
                    _map[x][y] = new FloppyRed(window, _tiles, x, y); // Can be picked up and placed. Explodes a short while after having been placed.
                else if(data.map[x + y * 60] == 21)
                    _map[x][y] = new Port2WayVert(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 22)
                    _map[x][y] = new Port2WayHoriz(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 23)
                    _map[x][y] = new Port4Way(window, _tiles, x, y);
                //24 - Electron Enemy that follows the left edge in it's moving direction. Generates infotrons when killed.
                else if(data.map[x + y * 60] == 25)
                    _map[x][y] = new Bug(window, _tiles, x, y); //Periodically sparks. Kills player if walking over when sparking.
                else if(data.map[x + y * 60] == 26)
                    _map[x][y] = new RamChipLeft(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 27)
                    _map[x][y] = new RamChipRight(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 28)
                    _map[x][y] = new Hardware1(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 29)
                    _map[x][y] = new Hardware2(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 30)
                    _map[x][y] = new Hardware3(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 31)
                    _map[x][y] = new Hardware4(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 32)
                    _map[x][y] = new Hardware5(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 33)
                    _map[x][y] = new Hardware6(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 34)
                    _map[x][y] = new Hardware7(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 35)
                    _map[x][y] = new Hardware8(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 36)
                    _map[x][y] = new Hardware9(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 37)
                    _map[x][y] = new Hardware10(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 38)
                    _map[x][y] = new RamChipTop(window, _tiles, x, y);
                else if(data.map[x + y * 60] == 39)
                    _map[x][y] = new RamChipBottom(window, _tiles, x, y);
                if(_map[x][y] !is null)
                    _map[x][y].load(this);
            }
        }
        centerView(window);
    }

    public void centerView(RenderWindow window)
    {
        auto view = window.view.dup;
        auto center = FloatRect(_murphy.x * 32, _murphy.y * 32, 32, 32).getCenter;
        auto viewXL = center.x - view.size.x / 2;
        auto viewYL = center.y - view.size.y / 2;
        auto viewXR = center.x + view.size.x / 2;
        auto viewYR = center.y + view.size.y / 2;
        if(viewXR > 60 * 32 - 16)
            center.x = 60 * 32 - view.size.x / 2 - 16;
        if(viewXL < 16)
            center.x = view.size.x / 2 + 16;
        if(viewYR > 24 * 32 - 16)
            center.y = 24 * 32 - view.size.y / 2 - 16;
        if(viewYL < 16)
            center.y = view.size.y / 2 + 16;
        view.center = center;
        window.view = view;
    }

    public auto get(int x, int y)
    {
        return _map[x][y];
    }

    public void destroy(int x, int y)
    {
        _map[x][y] = null;
    }

    public bool check(int x, int y)
    {
        if(_map[x][y] is null)
            return true;
        return false;
    }

    public MoveCheckResult checkMove(int x, int y, bool player, MoveDirection direction)
    {
        if(_map[x][y] is null)
            return MoveCheckResult.True;
        if(typeid(_map[x][y]) == typeid(Base))
            return player ? MoveCheckResult.True : MoveCheckResult.False;
        if(typeid(_map[x][y]) == typeid(Infotron))
            return player ? MoveCheckResult.True : MoveCheckResult.False;
        if(player && typeid(_map[x][y]) == typeid(Zonk))
        {
            auto object = cast(Zonk)_map[x][y];
            if(object.fall || object.moving)
                return MoveCheckResult.False;
            auto res = MoveCheckResult.False;
            if(direction == MoveDirection.Left && checkMove(object.x - 1, object.y, false, direction) == MoveCheckResult.True)
                res = MoveCheckResult.Push;
            else if(direction == MoveDirection.Right && checkMove(object.x + 1, object.y, false, direction) == MoveCheckResult.True)
                res = MoveCheckResult.Push;
            if(res == MoveCheckResult.Push)
            {
                object.pushed = true;
                object.setAnimation(direction);
                move(object, direction);
            }
            return res;
        }
        return MoveCheckResult.False;
    }

    public void move(GameObject object, MoveDirection direction)
    {
        object.oldX = object.x;
        object.oldY = object.y;
        object.direction = direction;
        auto player = typeid(object) == typeid(Murphy);
        auto res = MoveCheckResult.False;
        if(direction == MoveDirection.Up && (res = checkMove(object.x, object.y - 1, player, direction)) != MoveCheckResult.False)
            object.y = object.y - 1;
        else if(direction == MoveDirection.Down && (res = checkMove(object.x, object.y + 1, player, direction)) != MoveCheckResult.False)
            object.y = object.y + 1;
        else if(direction == MoveDirection.Left && (res = checkMove(object.x - 1, object.y, player, direction)) != MoveCheckResult.False)
            object.x = object.x - 1;
        else if(direction == MoveDirection.Right && (res = checkMove(object.x + 1, object.y, player, direction)) != MoveCheckResult.False)
            object.x = object.x + 1;
        if(res != MoveCheckResult.False)
        {
            if(_map[object.x][object.y] is null)
                _map[object.x][object.y] = new Dummy(null, null, object.x, object.y);
            if(res == MoveCheckResult.Push && player)
                (cast(Murphy)object).setPushAnimation(direction);
            object.moving = true;
            object.sprite.play(object.currentAnimation, &object.finishMove);
        }
        else
        {
            if(!object.pushed)
                _map[object.oldX][object.oldY] = null;
            _map[object.x][object.y] = object;
            object.direction = MoveDirection.None;
            object.stop();
            object.moving = false;
            object.pushed = false;
        }
    }

    public void finishMove(GameObject object)
    {
        if(!object.pushed)
            _map[object.oldX][object.oldY] = null;
        _map[object.x][object.y] = object;
        object.direction = MoveDirection.None;
        object.stop();
        object.moving = false;
        object.pushed = false;
    }

    public void explode(int ox, int oy)
    {
        for(auto i = -1; i <= 1; i++)
        {
            auto x = ox + i;
            if(x >= 60)
                continue;
            for(auto l = -1; l <= 1; l++)
            {
                auto y = oy + l;
                if(y >= 24)
                    continue;
                auto object = get(x, y);
                if(object !is null && typeid(object) == typeid(Wall))
                    continue;
                if(object !is null && typeid(object) == typeid(Murphy))
                    (cast(Murphy)object).dead = true;
                auto explosion = new Explosion(_window, _tiles, x, y);
                explosion.load(this);
                _map[x][y] = explosion;
            }
        }
    }

    public void draw()
    {
        foreach(ref row; _map)
        {
            foreach(ref cell; row)
            {
                if(cell !is null && typeid(cell) != typeid(Murphy))
                    cell.draw();
            }
        }
        if(!_murphy.dead)
            _murphy.draw();
    }

    public void update(Duration time)
    {
        foreach(ref row; _map)
        {
            foreach(ref cell; row)
            {
                if(cell !is null && typeid(cell) != typeid(Murphy))
                    cell.update(time);
            }
        }
        if(!_murphy.dead)
            _murphy.update(time);
        foreach(ref row; _map)
        {
            foreach_reverse(ref cell; row)
            {
                if(cell !is null)
                    cell.updateMove();
            }
        }
        foreach(ref row; _map)
        {
            foreach_reverse(ref cell; row)
            {
                if(cell !is null)
                    cell.updateMove2();
            }
        }
    }
}

