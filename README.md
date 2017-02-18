awesome-sharedtags
==================

A simple implementation for creating tags shared on multiple screens for
[awesome window manager](http://awesome.naquadah.org/).

This branch of the library is intended to work with *awesome* version 3.5 (and
all minor versions), but there are other branches with support for other
versions.

Features
--------

* Define a list of tags to be usable on all screens.
* Move tags with all clients between screens.
* Everything else should be just as usual.

Installation
------------

1. Clone or download a zip of the repository, and put the `sharedtags`
   directory somewhere where you can easily include it, for example in the same
   directory as your `rc.lua` file.
2. Modify your `rc.lua` file. A [patch](rc.lua.patch) against the default
   configuration is included in the repository for easy comparison, but keep
   reading for a textual description.
  1. Require the `sharedtags` library somewhere at the top of the file.

    ```lua
    local sharedtags = require("sharedtags")
    ```
  2. Create the tags using the `sharedtags()` method, instead of the original
     ones created with `awful.tag()`.

    ```lua
    local tags = sharedtags(
        { name = "main", layout = layouts[2] },
        { name = "www", layout = awful.layout.suit.max },
        { name = "chat", screen = 2, layout = layouts[1] },
        { layout = layouts[2] },
        { screen = 2, layout = layouts[2] }
    )
    ```
  3. The code for handling tags and clients needs to be changed to use the
     library.

    ```lua
    for i = 1, 9 do
        globalkeys = awful.util.table.join(globalkeys,
            -- View tag only.
            awful.key({ modkey }, "#" .. i + 9,
                function ()
                    local tag = tags[i]
                    if tag then
                        sharedtags.viewonly(tag)
                    end
                end),
            -- Toggle tag.
            awful.key({ modkey, "Control" }, "#" .. i + 9,
                function ()
                    local tag = tags[i]
                    if tag then
                        sharedtags.viewtoggle(tag)
                    end
                end),
            -- Move client to tag.
            awful.key({ modkey, "Shift" }, "#" .. i + 9,
                function ()
                    if client.focus then
                        local tag = tags[i]
                        if tag then
                            awful.client.movetotag(tag)
                        end
                    end
                end),
            -- Toggle tag.
            awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                function ()
                    if client.focus then
                        local tag = tags[i]
                        if tag then
                            awful.client.toggletag(tag)
                        end
                    end
                end))
    end
    ```
  4. Lastly, since the tag list is now a one-dimensional array, any references
     to the `tags` array needs to be changed, for example in the rules section.

    ```lua
    awful.rules.rules = {
        -- Set Firefox to always map on tag number 2.
        { rule = { class = "Firefox" },
          properties = { tag = tags[2] } }, -- or tags["www"] to map it to the name instead
    }
    ```
3. Restart or reload *awesome*.

Notes
-----

Because of constraints in the X server, *awesome* does not allow
toggling clients on tags allocated to other screens. Having a client on
multiple tags and moving one of the tags will cause the client to move as well.

API
---

See [`doc/index.html`](doc/index.html) for API documentation.

Credits
-------

Idea originally from https://github.com/lammermann/awesome-configs, but I could
not get that implementation to work.
