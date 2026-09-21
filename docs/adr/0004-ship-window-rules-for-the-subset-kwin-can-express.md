# Ship window rules for the subset KWin can express

Upstream's Hyprland configuration dims every window, centers floating windows, and
pins picture-in-picture windows to a corner. We decided the installer carries the
same intent into KWin's own window-rule layer rather than leaving it to a helper
script or to the user: `scripts/04a-window-rules.sh` writes three named groups into
`~/.config/kwinrulesrc` and asks KWin to reload once, after all of them are written.
The first group gives normal windows and dialogs an inactive opacity of 95 percent,
the second forces the centered placement policy on dialogs, and the third matches
upstream's `Picture(-| )in(-| )[Pp]icture` title and keeps that window above others.
The step is gated by `APPLY_WINDOW_RULES` and the percentage by `WINDOW_OPACITY`,
both with defaults, so an install that says nothing about window rules still gets
them. The groups only take effect because the script also writes the index that
names them: `[General] rules=`, the list KWin builds its rule book from, with the
`count` of the entries beside it.

Three costs come with a ruleset that lives in the user's own file. `kwinrulesrc`
holds the user's rules, so the script owns three groups and nothing else: it adds
and rewrites only their keys, it never truncates the file, and it never deletes a
group it did not write. The one key outside those groups it touches is the index,
and that key cannot be left alone. A group the list omits is not loaded at all, and
the next time KWin saves the rule book it deletes the group, in KWin 6.7 as in
master, so the group that is written without an index entry is a group that does
nothing. Naming only our own three would hand KWin a list that drops every rule the
user has, which is why the list is rebuilt as the union of the entries already in
it, every group the file holds and our three names, in that order, with the count of
them. The dialog rule overrides the user's global placement policy for dialogs. KWin
already sends dialogs through its dialog placement path under the global
`[Windows] Placement` policy, which
defaults to centered in a decorations build, so for most installs the rule changes
nothing; for a user who moved that policy it takes the choice away from dialogs, and
even centered placement still cascades a window that would cover another. The rule
names the dialog type only, so utility windows keep following the global policy. The
opacity rule is per activation state: KWin has separate active and inactive opacity
keys, upstream applies 0.95 to every window and excludes fullscreen ones, and there
is no match key for fullscreen, so we write only the inactive value. A window is
dimmed while it is not focused and returns to full opacity when it is, which is not
the rule upstream runs.

What cannot be expressed at all is left out rather than approximated. There is no
action that makes a window float or exempts it from tiling, because floating is a
property of the tiling model, and the port sets it through the tiling script's own
class list instead. There is no keep-aspect-ratio action. A rule size is an absolute
pixel pair rather than a percentage of the screen, and KWin honors it only for
windows it places rather than tiles or maximizes. No match key tests the client
library, so xwayland windows cannot be singled out, and matches are evaluated
against live properties, so a rule cannot match the class or the title a window
started with. That initial-title match is what upstream's larger ruleset uses to
place its sized floating windows, so that part of it is a gap here rather than a
translation, and the workspace routing it derives from the same ruleset is a
separate decision.
