--
-- Minimal "one window at a time" configuration.
--
-- There are no features. No keyboard control.
--

local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")

-- {{{ Layout

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts = {
    -- awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.floating,
}

-- }}}

-- {{{ Tags
local tags = {}
awful.screen.connect_for_each_screen(function(s)
    tags[s] = awful.tag({"1"}, s, layouts[1])
end)
-- }}}

-- {{{ Wibox
local mywibox = {}
awful.screen.connect_for_each_screen(function(s)
    -- Hmmm, this is weird, but I *have* to add a wibar.
    -- Otherwise awesome will not resize windows when onboard resizes...
    -- Weird, eh?
    mywibox[s] = awful.wibar({ position = "top", screen = s, visible = false })
end)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
        properties = {
            border_width = 0,
            focus = awful.client.focus.filter,
            raise = true,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen,
        }
    },

    -- XFCE notification
    -- Otherwise all notifications will interrupt input with a HW (bluetooth) keyboard
    { rule = { instance = "xfce4-notifyd", class = "Xfce4-notifyd" },
        properties = {
            border_width = 0,
            sticky = true,
            focusable = false,
            nofocus = true,
            ontop = true;
        }
    },

    -- Onboard on-screen keyboard
    { rule = { instance = "onboard", class = "Onboard" },
        properties = {
            border_width = 0,
            sticky = true,
            focusable = false,
            nofocus = true,
            ontop = true;
        }
    },

    -- Xfce desktop
    -- Allows its use in all tags.
    { rule = { instance = "xfdesktop", class = "Xfdesktop" },
        properties = {
            border_width = 0,
            sticky = true,
            focusable = false,
            nofocus = true,
        }
    },
        
}
-- }}}

-- {{{ Signals

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

-- }}}
