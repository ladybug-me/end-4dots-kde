# Line KDE's idle-suspend timers up with Caelestia's

Setting "Idle suspend" to 30 minutes in Nexus suspended the machine at about 10
minutes on battery. Two timers were running and nothing said so. One is
Caelestia's own idle-timeout list, driven by the Wayland idle-notify protocol via
Quickshell; the other is powerdevil's, held in
`~/.config/powermanagementprofilesrc` per power profile, with defaults that
suspend after 15 minutes on AC and 10 on battery on a laptop. Whichever timer has
the shorter timeout wins, so the user's setting only held when it happened to be
the shorter of two numbers they could not see together.

We decided that while Caelestia has a suspend idle action enabled it also states
that timeout to powerdevil: for the AC and Battery profiles whose action is sleep
or hibernate, `AutoSuspendIdleTimeoutSec` is set to the Caelestia timeout, which
is the shortest enabled suspend action because that is the one that fires. A
profile powerdevil would not suspend from is left alone, the low battery profile
is never touched, and an install with no suspend action keeps KDE's configuration
exactly as its user left it. The mirror runs when the setting changes and once
when the config lands; it reads before it writes, so a value that already matches
is not rewritten, and a write that fails is reported in the shell rather than
swallowed, because a mirror that quietly did nothing would put the user back
where this started.

Not touching KDE and warning about the conflict instead was the first
alternative. It tells the user that the setting they just made does not work and
leaves them to fix it in System Settings, which is a worse answer than making the
two agree.

Retiring powerdevil's timer altogether (setting its action to `NoAction` while
Caelestia owns suspend) was the second. It is the cleaner end state, one timer
instead of two, but it needs the user's own action, timeout and sleep mode
remembered somewhere so that turning the Nexus toggle off can put them back, and
that state is exactly the kind of thing that goes stale. A mirror states the same
intent in both places, needs no memory and can be repeated at any time.

Making powerdevil the only owner was the third: write the Nexus timeout into
powerdevil and drop the Caelestia timer. That deletes the idle-timeout list this
shell shares with upstream, which also drives the lock and display-off actions,
so it is a much larger change than the bug warrants.

Three costs come with the mirror. It writes a KDE configuration file, so System
Settings will show the mirrored value - which is the point, but it is our write.
The low battery profile keeps its own, earlier timeout, so a nearly empty battery
still sleeps before the idle preference; that profile exists to save the machine,
not to express a preference, and it is the one case where being overridden is
correct. And only the timeout is mirrored, not powerdevil's sleep mode, so the two
timers can ask for sleep at the same moment with different modes; the second
request is redundant rather than coordinated, which is what mirroring one number
instead of taking over KDE's action costs.
