module objects.reservation;

import dsfml.graphics;
import gameobject;
import level;

// Cell placeholder for the C state machine's tile/state reservation
// sentinels. In Supaplex's original engine, reservations overwrite both
// bytes of a StatefulLevelTile simultaneously — e.g. (0x88, 0x88) marks
// the destination of an in-progress slide so other movers treat the cell
// as claimed. In this port the Reservation class occupies the _map cell
// and carries the sentinel value in its .state byte for queries.
enum ReservationKind : ubyte
{
    // Slide-destination reservation (tile/state both 0x88). Set at the
    // start of a slide to claim the destination cell against other
    // simultaneous movers.
    Slide = 0x88,
    // Fall-reservation (0x99). Placed on the cell immediately below a
    // falling zonk/infotron when it enters the 0x70 continuation state,
    // reserving that cell for the next tick's fall commit.
    Fall = 0x99,
    // Post-slide-sibling marker (0xAA). Planted on the sibling cell of
    // a committing slide so the cascade sees it as a slide-accepting
    // transient space rather than empty space.
    AltSpace = 0xAA,
    // Cleared-transient (0xFF). Marks an origin cell that was vacated
    // by a committing fall/slide; the cascade's "initial clear" turns
    // this back into real Space.
    Cleared = 0xFF,
}

class Reservation : GameObject
{
    private ReservationKind _kind;

    this(int x, int y, ReservationKind kind)
    {
        super(null, null, x, y);
        _kind = kind;
        _state = cast(ubyte)kind;
    }

    @property public ReservationKind kind()
    {
        return _kind;
    }

    public override void load(Level level)
    {
        _level = level;
    }

    public override void stop()
    {}

    public override void draw()
    {}

    public override void update(Duration time)
    {}
}
