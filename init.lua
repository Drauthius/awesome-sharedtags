--- Provides functionality to share tags across all screens in awesome WM.
-- @module sharedtags
-- @author Albert Diserholt
-- @copyright 2016 Albert Diserholt
-- @license MIT

-- Grab environment we need
local awful = require("awful")
local capi = {
    tag = tag,
    screen = screen,
    mouse = mouse
}

local sharedtags = {
    _VERSION = "sharedtags v1.0.0",
    _DESCRIPTION = "Share tags for awesome window manager",
    _URL = "https://github.com/Drauthius/awesome-sharedtags",
    _LICENSE = [[
        MIT LICENSE

        Copyright (c) 2016 Albert Diserholt

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the "Software"),
        to deal in the Software without restriction, including without limitation
        the rights to use, copy, modify, merge, publish, distribute, sublicense,
        and/or sell copies of the Software, and to permit persons to whom the
        Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in
        all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
        FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
        IN THE SOFTWARE.
    ]]
}

--- Create new tag objects.
-- The first tag defined for each screen will be automatically selected.
-- @tparam table def A list of tables with the optional keys `name`, `layout`
-- and `screen`. The `name` value is used to name the tag and defaults to the
-- list index. The `layout` value sets the starting layout for the tag and
-- defaults to the first layout. The `screen` value sets the starting screen
-- for the tag and defaults to the first screen. The tags will be sorted in this
-- order in the default taglist.
-- @treturn table A list of all created tags.
-- @usage local tags = sharedtags(
--   -- "main" is the first tag starting on screen 2 with the tile layout.
--   { name = "main", layout = awful.layout.suit.tile, screen = 2 },
--   -- "www" is the second tag on screen 1 with the floating layout.
--   { name = "www" },
--   -- Third tag is named "3" on screen 1 with the floating layout.
--   {})
function sharedtags.new(def)
    local tags = {}

    for i,t in ipairs(def) do
        tags[i] = awful.tag.add(t.name or i, {
            screen = math.min(capi.screen.count(), t.screen or 1),
            layout = t.layout,
            sharedtagindex = i
        })

        -- If no tag is selected for this screen, then select this one.
        if not awful.tag.selected(awful.tag.getscreen(tags[i])) then
            awful.tag.viewonly(tags[i]) -- Updates the history as well.
        end
    end

    return tags
end

--- Move the specified tag to a new screen, if necessary.
-- @param tag The tag to move.
-- @tparam[opt=capi.mouse.screen] number screen The screen to move the tag to.
-- @treturn bool Whether the tag was moved.
function sharedtags.movetag(tag, screen)
    screen = screen or capi.mouse.screen
    local oldscreen = awful.tag.getscreen(tag)

    -- If the specified tag is allocated to another screen, we need to move it.
    if oldscreen ~= screen then
        local oldsel = awful.tag.selected(oldscreen)

        -- This works around a bug in the taglist module. It only receives
        -- signals for when a tag or client changes something. Moving a tag
        -- with no clients doesn't trigger a signal, and can thus leave the
        -- taglist outdated. The work around is to hide the tag prior to the
        -- move, and then restore its hidden status.
        local hide = awful.tag.getproperty(tag, "hide")
        awful.tag.setproperty(tag, "hide", true)

        awful.tag.setscreen(tag, screen)

        awful.tag.setproperty(tag, "hide", hide)

        if oldsel == tag then
            -- The tag has been moved away. In most cases the tag history
            -- function will find the best match, but if we really want we can
            -- try to find a fallback tag as well.
            if not awful.tag.selected(oldscreen) then
                local newtag = awful.tag.find_fallback(oldscreen)
                if newtag then
                    awful.tag.viewonly(newtag)
                else
                end
            end
        else
            -- A bit of a weird one. Moving a previously selected tag
            -- deselects the current tag, probably because the history is
            -- restored to the first entry. Restoring it to the previous entry
            -- seems to work well enough.
            awful.tag.history.restore(oldscreen, "previous")
        end

        -- Also sort the tag in the taglist, by reapplying the index. This is just a nicety.
        for _,screen in ipairs({ screen, oldscreen }) do
            for _,t in ipairs(awful.tag.gettags(screen)) do
                awful.tag.setproperty(t, "index", awful.tag.getproperty(t, "sharedtagindex"))
            end
        end

        return true
    end

    return false
end

--- View the specified tag on the specified screen.
-- @param tag The only tag to view.
-- @tparam[opt=capi.mouse.screen] number screen The screen to view the tag on.
function sharedtags.viewonly(tag, screen)
    sharedtags.movetag(tag, screen)
    awful.tag.viewonly(tag)
end

--- Toggle the specified tag on the specified screen.
-- The tag will be selected if the screen changes, and toggled if it does not
-- change the screen.
-- @param tag The tag to toggle.
-- @tparam[opt=capi.mouse.screen] number screen The screen to toggle the tag on.
function sharedtags.viewtoggle(tag, screen)
    local oldscreen = awful.tag.getscreen(tag)

    if sharedtags.movetag(tag, screen) then
        -- Always mark the tag selected if the screen moved. Just feels a lot
        -- more natural.
        tag.selected = true
        -- Update the history on the old and new screens.
        capi.screen[oldscreen]:emit_signal("tag::history::update")
        capi.screen[awful.tag.getscreen(tag)]:emit_signal("tag::history::update")
    else
        -- Only toggle the tag unless the screen moved.
        awful.tag.viewtoggle(tag)
    end
end

capi.tag.add_signal("property::sharedtagindex")

return setmetatable(sharedtags, { __call = function(...) return sharedtags.new(select(2, ...)) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
