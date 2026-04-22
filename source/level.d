module level;

import std.stdio;
import std.parallelism;
import std.conv;
import dsfml.graphics;
import gameobject;
import utils;
import interfaces;
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
import objects.explosion;
import objects.reservation;

struct LevelPort
{
    byte hi; //(2*(x+y*60)) div 256 (integer division) where (x,y) are the coordinates of the special port (0,0=left top)
    byte lo; //(2*(x+y*60)) mod 256 (remainder of division) where (x,y) are the coordinates of the special port (0,0=left top)
    byte gravity; //1 (turn on) or 0 (turn off) gravity
    byte fr_zonks; //2 (turn on) or 0 (turn off) freeze zonks
    byte fr_enemy; //1 (turn on) or 0 (turn off) freeze enemies
    byte unused;
}

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
}

class Level
{
    private float _width;
    private float _height;
    private GameObject[][] _map;
    private Murphy _murphy;
    private RenderWindow _window;
    private Texture _tiles;

    // The C original runs physics at ~35 Hz (the VGA frame rate it targeted).
    // We accumulate wall-clock time here and drain one physics tick every
    // _simTickDur regardless of the surrounding 120 fps render loop.
    private Duration _simAccumulator;
    private Duration _simTickDur = dur!"msecs"(28);

    // Fraction of the current sim tick already elapsed (0..1). Used by
    // state-machine-driven renderers (Zonk/Infotron) to interpolate the
    // visual sub-tile position between discrete 35 Hz sim steps so that at
    // higher render rates (e.g. 120 fps) falls and slides look smooth
    // instead of stepping by 4 px every 28 ms.
    public float subTickFraction() const
    {
        auto num = _simAccumulator.total!"hnsecs";
        auto den = _simTickDur.total!"hnsecs";
        if(den <= 0)
            return 0f;
        float f = cast(float)num / cast(float)den;
        if(f < 0f) f = 0f;
        if(f > 1f) f = 1f;
        return f;
    }

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
        auto immutable viewXL = center.x - view.size.x / 2;
        auto immutable viewYL = center.y - view.size.y / 2;
        auto immutable viewXR = center.x + view.size.x / 2;
        auto immutable viewYR = center.y + view.size.y / 2;
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
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return null;
        return _map[x][y];
    }

    public void destroy(int x, int y)
    {
        _map[x][y] = null;
    }

    public bool check(int x, int y)
    {
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return false;
        return _map[x][y] is null;
    }

    // --- state-machine helpers ---

    // True if (x, y) is an empty Space cell (null, no object, no reservation).
    public bool isSpace(int x, int y)
    {
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return false;
        return _map[x][y] is null;
    }

    // True if (x, y) is Space OR a Reservation of any of the listed kinds.
    public bool isSpaceOrReservation(int x, int y, ReservationKind[] kinds...)
    {
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return false;
        if(_map[x][y] is null)
            return true;
        auto r = cast(Reservation)_map[x][y];
        if(r is null)
            return false;
        foreach(k; kinds)
            if(r.kind == k)
                return true;
        return false;
    }

    // True if (x, y) contains a resting tile (state 0, not moving) that can
    // act as a support cell for a slide above: Zonk, Infotron, or RamChip
    // centre variant. Other RamChip variants are decorative edges and do
    // NOT support slides (matching the C LevelTileTypeChip check).
    public bool isRestingSlideSupport(int x, int y)
    {
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return false;
        auto cell = _map[x][y];
        if(cell is null || cell.state != 0 || cell.moving)
            return false;
        return cast(Zonk)cell !is null
            || cast(Infotron)cell !is null
            || (typeid(cell) == typeid(RamChip));
    }

    public void reserve(int x, int y, ReservationKind kind)
    {
        _map[x][y] = new Reservation(x, y, kind);
        _map[x][y].load(this);
    }

    public void clearCell(int x, int y)
    {
        _map[x][y] = null;
    }

    public void setCell(int x, int y, GameObject obj)
    {
        _map[x][y] = obj;
    }

    public MoveCheckResult checkMove(int x, int y, GameObject object, MoveDirection direction)
    {
        if(x < 0 || x >= 60 || y < 0 || y >= 24)
            return MoveCheckResult.False;
        if(_map[x][y] is null)
            return MoveCheckResult.True;
        auto player = cast(Murphy)object;
        auto consumable = cast(IConsumable)_map[x][y];
        if(consumable !is null)
            return player !is null ? MoveCheckResult.True : MoveCheckResult.False;
        if(player is null)
            return MoveCheckResult.False;
        auto object2 = _map[x][y]; // @suppress(dscanner.suspicious.unmodified)
        if(object2.fall || object2.moving)
            return MoveCheckResult.False;
        // Reservations mark cells in mid-slide / mid-fall / mid-walk and
        // block Murphy regardless of kind.
        if(cast(Reservation)object2 !is null)
            return MoveCheckResult.False;
        auto pushable = cast(IPushable)object2;
        auto useable = cast(IUseable)object2;
        if(useable !is null)
            useable.use(player, direction);
        if(pushable is null)
            return MoveCheckResult.False;
        return pushable.push(player, direction);
    }

    public void move(GameObject object, MoveDirection direction)
    {
        object.oldX = object.x;
        object.oldY = object.y;
        object.direction = direction;
        auto res = MoveCheckResult.False;
        if(direction == MoveDirection.Up &&
         (res = checkMove(object.x, object.y - 1, object, direction)) != MoveCheckResult.False)
            object.y = object.y - 1;
        else if(direction == MoveDirection.Down &&
         (res = checkMove(object.x, object.y + 1, object, direction)) != MoveCheckResult.False)
            object.y = object.y + 1;
        else if(direction == MoveDirection.Left &&
         (res = checkMove(object.x - 1, object.y, object, direction)) != MoveCheckResult.False)
            object.x = object.x - 1;
        else if(direction == MoveDirection.Right &&
         (res = checkMove(object.x + 1, object.y, object, direction)) != MoveCheckResult.False)
            object.x = object.x + 1;
        if(res != MoveCheckResult.False)
        {
            if(_map[object.x][object.y] is null)
                reserve(object.x, object.y, ReservationKind.Cleared);
            object.moving = true;
            object.sprite.play(object.currentAnimation, &object.finishMove);
        }
        else
        {
            if(!object.pushed)
                _map[object.oldX][object.oldY] = null;
            _map[object.x][object.y] = object;
            object.direction = MoveDirection.None;
            //object.stop();
            object.moving = false;
            object.pushed = false;
        }
    }

    public void finishMove(GameObject object)
    {
        immutable int oldX = object.oldX;
        immutable int oldY = object.oldY;
        immutable bool wasPushed = object.pushed;
        if(!wasPushed && _map[oldX][oldY] is object)
            _map[oldX][oldY] = null;
        _map[object.x][object.y] = object;
        object.direction = MoveDirection.None;
        object.stop();
        object.moving = false;
        object.pushed = false;
    }

    public void disappear(GameObject object, MoveDirection direction)
    {
        GameObject obj = null;
        if(direction == MoveDirection.Up)
            obj = get(object.x, object.y - 1);
        else if(direction == MoveDirection.Down)
            obj = get(object.x, object.y + 1);
        else if(direction == MoveDirection.Left)
            obj = get(object.x - 1, object.y);
        else if(direction == MoveDirection.Right)
            obj = get(object.x + 1, object.y);

        auto consumable = cast(IConsumable)obj;

        if(consumable is null)
            return;

        consumable.startDisappear();
        object.sprite.play(object.currentAnimation, null);
    }

    public void explode(int ox, int oy)
    {
        for(auto i = -1; i <= 1; i++)
        {
            auto x = ox + i;
            if(x < 0 || x >= 60)
                continue;
            for(auto l = -1; l <= 1; l++)
            {
                auto y = oy + l;
                if(y < 0 || y >= 24)
                    continue;
                auto object = get(x, y);
                auto nonDestructible = cast(INonDestructible)object;
                if(nonDestructible !is null)
                    continue;
                if(object !is null && typeid(object) == typeid(Murphy))
                    (cast(Murphy)object).dead = true;
                auto explosion = new Explosion(_window, _tiles, x, y);
                explosion.load(this);
                _map[x][y] = explosion;
            }
        }
    }

    public void explode()
    {
        foreach(ref row; _map)
        {
            foreach(ref cell; row)
            {
                auto explosive = cast(IExplosive)cell;
                if(explosive !is null)
                    explode(cell.x, cell.y);
            }
        }
    }

    public void draw()
    {
        foreach(ref row; _map)
        {
            foreach(ref cell; row)
            {
                if(cell !is null
                    && typeid(cell) != typeid(Murphy)
                    && cast(Reservation)cell is null)
                    cell.draw();
            }
        }
        if(!_murphy.dead)
            _murphy.draw();
    }

    public void update(Duration time)
    {
        // Animation / input pass runs every wall-clock frame.
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

        // Drain physics ticks from the accumulator. The sim runs at a fixed
        // rate decoupled from rendering so state-machine advancement matches
        // the C original's timing regardless of the surrounding frame rate.
        _simAccumulator += time;
        while(_simAccumulator >= _simTickDur)
        {
            _simAccumulator -= _simTickDur;
            _stepSim();
        }
    }

    // One sim-tick pass. Iterates the grid top-to-bottom, left-to-right —
    // matching updateMovingObjects in the C original — and invokes
    // updateState on each object that still occupies the position it was
    // snapshotted at. Taking a snapshot at tick start is load-bearing: a
    // zonk that commits a downward move mid-tick (e.g. at state 0x42)
    // would otherwise be visited a second time when the iteration reaches
    // its new row.
    private void _stepSim()
    {
        static struct Pos { int x; int y; }
        Pos[] positions;
        positions.reserve(64);
        // Only snapshot cells whose tile has a moving function (C's
        // movingFunctions table: Zonk, Infotron, OrangeDisk, Explosion,
        // etc.). C's filter `tile & 13 != 0 && tile < 0x20` excludes
        // reservation sentinels (0x88/0x99/0xAA/0xFF). If we included
        // reservations and a slide-right commit swapped in a zonk at
        // the reservation's cell mid-tick, iteration would reach the
        // zonk at its new position later and advance its state a
        // second time — a double-tick bug.
        for(int y = 0; y < 24; y++)
        {
            for(int x = 0; x < 60; x++)
            {
                auto cell = _map[x][y];
                if(cell is null)
                    continue;
                if(cast(Reservation)cell !is null)
                    continue;
                if(cell.x != x || cell.y != y)
                    continue;
                positions ~= Pos(x, y);
            }
        }
        foreach(pos; positions)
        {
            auto cell = _map[pos.x][pos.y];
            if(cell is null)
                continue;
            if(cast(Reservation)cell !is null)
                continue;
            if(cell.x != pos.x || cell.y != pos.y)
                continue;
            cell.updateState(this);
        }
    }
}
