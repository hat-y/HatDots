-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- HatDots: notify newsboat's unread count once the desktop has settled
-- (was `hl.on("hyprland.start", ...)` under the old hl.* API; the current
-- o.exec_on_start() is its direct replacement).
o.exec_on_start("sleep 5 && hat-news")

-- Fix audio: headphone volume and auto-mute (Realtek ALC897)
-- Hardware-specific: targets this PC's sound card (ALSA card index 2).
-- Harmless on other machines since amixer's output and errors are
-- discarded either way.
o.exec_on_start("amixer -c 2 sset 'Headphone' 70 unmute > /dev/null 2>&1")
o.exec_on_start("amixer -c 2 sset 'Auto-Mute Mode' Disabled > /dev/null 2>&1")
