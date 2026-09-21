# Do not create or route into KDE Activities automatically

Upstream's ruleset tags a window by class, with `btop`, the music players, the chat
apps and todoist among the classes it names, and points that tag at a special
workspace, so it opens somewhere the user does not see in the normal strip. We
decided the port does not create KDE Activities, does not route any application into
one, and does not assign applications to virtual desktops either. A user who wants
routing can express it in a rule of their own, matched on class or title, using the
`activity` and `activityrule` keys or the `desktops` and `desktopsrule` keys.

Three pieces of the upstream ruleset have no KWin equivalent, which is why an
automatic version was rejected. Window rules cannot match a window's initial title
or initial class, only its live ones. The tag is a second layer of indirection
between the match and the workspace, and the rule layer has no equivalent of it.
There is also no special workspace to route into. An automatic version would have to
invent the missing layer: create Activities named after upstream's categories, in a
session that uses none today, and guess which of them each matched window belongs
in. It would also have to name ids it does not have. The `activity` and `desktops`
keys take the ids KWin generates for the Activities and desktops that exist, not
positions, so a ruleset written at install time cannot name them: the virtual
desktops the installer configures are created by KWin afterwards.

The first alternative was to ship the routing anyway, with the installer creating
and naming the Activities. That adds Activities the user did not ask for, and pins
rules to ids we would then have to keep in sync with a session we do not own. The
second was to route the same classes onto the numbered virtual desktops the
installer already configures. That reuses a layout the user owns to answer a
question the issue only asks to have answered, and which application belongs on
which desktop is a preference that is not ours. Documenting the two rule keys
instead costs a paragraph and leaves the choice with the user.
