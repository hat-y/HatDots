-- Extra autostart processes.
hl.on("hyprland.start", function()
  hl.exec_cmd("sleep 5 && hat-news")
end)
