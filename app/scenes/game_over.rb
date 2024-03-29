module Scene
  class << self
    # Shown after the player dies
    def tick_game_over(args)
      draw_bg(args, DARK_BLUE)

      labels = []

      labels << label(:game_over, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG, font: FONT_BOLD)
      labels << label("#{text(:level)}: #{args.state.player.level}", x: args.grid.w / 2, y: args.grid.top - 320, size: SIZE_SM, align: ALIGN_CENTER)
      labels << label("#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}", x: args.grid.w / 2, y: args.grid.top - 380, size: SIZE_SM, align: ALIGN_CENTER)
      labels << label(:restart, x: args.grid.w / 2, y: args.grid.top - 480, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)

      if primary_down?(args.inputs)
        return Scene.switch(args, :gameplay, reset: true)
      end

      args.outputs.labels << labels
    end
  end
end
