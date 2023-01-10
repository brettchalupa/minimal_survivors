# Code that only gets run once on game start
def init(args)
  GameSetting.load_settings(args)
  args.gtk.hide_cursor
end

def tick(args)
  init(args) if args.state.tick_count == 0

  # this looks good on non 16:9 resolutions; game background is different
  args.outputs.background_color = TRUE_BLACK.values

  args.state.has_focus ||= true
  args.state.scene ||= :main_menu

  Scene.send("tick_#{args.state.scene}", args)

  debug_tick(args)
end

# code that only runs while developing
# contains lots of development shortcuts and helpers
def debug_tick(args)
  return unless debug?

  debug_label(args, args.grid.right - 24, args.grid.top, "#{args.gtk.current_framerate.round}")

  if args.inputs.keyboard.key_down.i
    play_sfx(args, :select)
    Sprite.reset_all(args)
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    play_sfx(args, :select)
    $gtk.reset
  end

  if args.inputs.keyboard.key_down.zero
    play_sfx(args, :select)
    args.state.render_debug_details = !args.state.render_debug_details
  end

  player = args.state.player
  if player
    if args.inputs.keyboard.key_down.one
      play_sfx(args, :select)
      Player.level_up(args, player)
    end

    if args.inputs.keyboard.key_down.two
      play_sfx(args, :select)
      player.invincible = !player.invincible
      args.gtk.notify!("Player invincibility toggled")
    end
    if player.invincible && args.state.scene == :gameplay
      args.outputs.labels << label("inv", x: player.x + player.w / 2, y: player.y + player.h + 16, align: ALIGN_CENTER, size: SIZE_XS)
    end
  end
end
