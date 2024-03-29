module Scene
  class << self
    def tick_main_menu(args)
      draw_bg(args, DARK_PURPLE)
      options = [
        {
          key: :start,
          on_select: -> (args) { Scene.switch(args, :gameplay, reset: true) }
        },
        {
          key: :settings,
          on_select: -> (args) { Scene.switch(args, :settings, reset: true, return_to: :main_menu) }
        },
      ]

      if args.gtk.platform?(:desktop)
        options << {
          key: :quit,
          on_select: -> (args) { args.gtk.request_quit }
        }
      end

      Menu.tick(args, :main_menu, options)

      labels = []
      labels << label(
        title.upcase, x: args.grid.w / 2, y: args.grid.top - 100,
        size: SIZE_LG, align: ALIGN_CENTER, font: FONT_BOLD_ITALIC)
      labels << label(
        "#{text(:made_by)} #{CREDITS.join(', ')}",
        x: args.grid.left + 24, y: 48,
        size: SIZE_XS, align: ALIGN_LEFT)
      labels << label(
        :controls_title,
        x: args.grid.right - 24, y: 84,
        size: SIZE_SM, align: ALIGN_RIGHT)
      labels << label(
        args.inputs.controller_one.connected ? :controls_gamepad : :controls_keyboard,
        x: args.grid.right - 24, y: 48,
        size: SIZE_XS, align: ALIGN_RIGHT)
      labels << label(
        "v" + version, x: 24.from_left, y: 24.from_top,
        size: SIZE_XS, align: ALIGN_LEFT, font: FONT_REGULAR)

      args.outputs.labels << labels
    end

  end
end
