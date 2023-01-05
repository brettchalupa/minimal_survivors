module Scene
  class << self
    def tick_settings(args)
      draw_bg(args, DARK_GREEN)

      options = [
        {
          key: :sfx,
          kind: :toggle,
          setting_val: args.state.setting.sfx,
          on_select: -> (args) { args.state.setting.sfx = !args.state.setting.sfx; save_settings(args) }
        },
        {
          key: :back,
          on_select: -> (args) { Scene.switch(args, :back) }
        },
      ]

      if args.gtk.platform?(:desktop)
        options.insert(options.length - 1, {
          key: :fullscreen,
          kind: :toggle,
          setting_val: args.state.setting.fullscreen,
          on_select: -> (args) { toggle_fullscreen(args); save_settings(args) }
        })
      end

      Menu.tick(args, :settings, options)

      args.outputs.labels << label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
    end
  end
end
