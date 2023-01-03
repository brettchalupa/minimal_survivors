FPS = 60
ALIGN_LEFT = 0
ALIGN_CENTER = 1
ALIGN_RIGHT = 2
BLEND_NONE = 0
BLEND_ALPHA = 1
BLEND_ADDITIVE = 2
BLEND_MODULO = 3
BLEND_MULTIPLY = 4

TRUE_BLACK = { r: 0, g: 0, b: 0 }
BLACK = { r: 25, g: 25, b: 25 }
WHITE = { r: 255, g: 255, b: 255 }

DIR_DOWN = :down
DIR_UP = :up
DIR_LEFT = :left
DIR_RIGHT = :right

module Sprite
  # annoying to track but useful for reloading with +i+ in debug mode; would be
  # nice to define a different way
  SPRITES = {
    bullet: "sprites/bullet.png",
    enemy: "sprites/enemy.png",
    exp_chip: "sprites/exp_chip.png",
    familiar: "sprites/familiar.png",
    player: "sprites/player.png",
  }

  class << self
    def reset_all(args)
      SPRITES.each { |_, v| args.gtk.reset_sprite(v) }
    end

    def for(key)
      SPRITES.fetch(key)
    end
  end
end

# Code that only gets run once on game start
def init(args)
end

def tick(args)
  init(args) if args.state.tick_count == 0

  args.outputs.background_color = TRUE_BLACK.values
  args.state.has_focus ||= true
  args.state.scene ||= :main_menu

  send("tick_scene_#{args.state.scene}", args)

  debug_tick(args)
end

def tick_scene_main_menu(args)
  options = [
    {
      text: text(:start),
      on_select: -> (args) { switch_scene(args, :gameplay) }
    },
    {
      text: text(:settings),
      on_select: -> (args) { switch_scene(args, :settings) }
    },
  ]

  if args.gtk.platform?(:desktop)
    options << {
      text: text(:quit),
      on_select: -> (args) { args.gtk.request_quit }
    }
  end

  tick_menu(args, :main_menu, options)

  args.outputs.labels << label(
    title, x: args.grid.w / 2, y: args.grid.top - 100,
    size: SIZE_LG, align: ALIGN_CENTER)
end

def switch_scene(args, scene, reset: false)
  if reset
    case scene
    when :gameplay
      args.state.player = nil
      args.state.enemies = nil
      args.state.enemies_destroyed = nil
      args.state.exp_chips = nil
    end
  end

  args.state.scene = scene
end

def tick_scene_gameplay(args)
  args.state.player ||= begin
    p = {
      x: args.grid.w / 2,
      y: args.grid.h / 2,
      w: 32,
      h: 32,
      health: 6,
      speed: 5,
      exp: 0,
      path: Sprite.for(:player),
      bullets: [],
      exp_chip_magnetic_dist: 50,
      bullet_delay: BULLET_DELAY,
      direction: DIR_UP,
    }.merge(WHITE)

    p.define_singleton_method(:dead) do
      health <= 0
    end

    p
  end

  args.state.enemies ||= []
  args.state.enemies_destroyed ||= 0
  args.state.exp_chips ||= []

  if !args.state.has_focus && args.inputs.keyboard.has_focus
    args.state.has_focus = true
  elsif args.state.has_focus && !args.inputs.keyboard.has_focus
    args.state.has_focus = false
  end

  if !args.state.has_focus || pause_down?(args)
    return switch_scene(args, :paused)
  end

  # spawn a new enemy every 5 seconds
  if args.state.tick_count % FPS * 10 == 0
    args.state.enemies << spawn_enemy(args)
  end

  tick_player(args, args.state.player)
  args.state.enemies.each { |e| tick_enemy(args, e)  }
  args.state.exp_chips.each { |c| tick_exp_chip(args, c)  }
  collide(args, args.state.player.bullets, args.state.enemies, -> (args, bullet, enemy) do
    bullet.dead = true
    destroy_enemy(args, enemy)
  end)
  collide(args, args.state.enemies, args.state.player, -> (args, enemy, player) do
    player.health -= 1
    destroy_enemy(args, enemy)
  end)
  collide(args, args.state.enemies, args.state.player.familiar, -> (args, enemy, familiar) do
    destroy_enemy(args, enemy)
  end)
  collide(args, args.state.exp_chips, args.state.player, -> (args, exp_chip, player) do
    exp_chip.dead = true
    player.exp += exp_chip.exp_amount
  end)
  args.state.enemies.reject! { |e| e.dead }
  args.state.exp_chips.reject! { |e| e.dead }

  if args.state.player.dead
    return switch_scene(args, :game_over)
  end

  args.outputs.solids << { x: args.grid.left, y: args.grid.bottom, w: args.grid.w, h: args.grid.h }.merge(BLACK)
  args.outputs.sprites << [args.state.exp_chips, args.state.player.bullets, args.state.player, args.state.enemies, args.state.player.familiar]

  labels = []
  labels << label("#{text(:health)}: #{args.state.player.health}", x: 40, y: args.grid.top - 40, size: SIZE_SM)
  labels << label("#{text(:exp)}: #{args.state.player.exp}", x: 40, y: args.grid.top - 72, size: SIZE_SM)
  labels << label("#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}", x: args.grid.right - 40, y: args.grid.top - 40, size: SIZE_SM, align: ALIGN_RIGHT)
  args.outputs.labels << labels
end

def destroy_enemy(args, enemy)
  enemy.dead = true
  args.state.enemies_destroyed += 1
  rand(3).times do |i|
    args.state.exp_chips << {
      x: enemy.x + enemy.w / 2 + (-5..5).to_a.sample + i * 5,
      y: enemy.y + enemy.h / 2 + (-5..5).to_a.sample + i * 5,
      speed: 6,
      angle: rand(360),
      w: 12,
      h: 12,
      dead: false,
      exp_amount: 1,
      path: Sprite.for(:exp_chip)
    }
  end
end

def tick_scene_paused(args)
  labels = []

  labels << label(:paused, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:resume, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)

  if primary_down?(args.inputs)
    return switch_scene(args, :gameplay)
  end

  args.outputs.labels << labels
end

def tick_scene_settings(args)
  labels = []

  labels << label(:settings, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:back, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)

  if primary_down?(args.inputs)
    return switch_scene(args, :main_menu)
  end

  args.outputs.labels << labels
end

def tick_scene_game_over(args)
  labels = []

  labels << label(:game_over, x: args.grid.w / 2, y: args.grid.top - 200, align: ALIGN_CENTER, size: SIZE_LG)
  labels << label(:restart, x: args.grid.w / 2, y: args.grid.top - 420, align: ALIGN_CENTER, size: SIZE_SM).merge(a: args.state.tick_count % 155 + 100)
  labels << label("#{text(:enemies_destroyed)}: #{args.state.enemies_destroyed}", x: args.grid.w / 2, y: args.grid.top - 320, size: SIZE_SM, align: ALIGN_CENTER)

  if primary_down?(args.inputs)
    return switch_scene(args, :gameplay, reset: true)
  end

  args.outputs.labels << labels
end

TEXT = {
  back: "Shoot to go back",
  enemies_destroyed: "Enemies Destroyed",
  exp: "Exp",
  game_over: "Game Over",
  health: "Health",
  paused: "Paused",
  quit: "Quit",
  restart: "Shoot to Restart",
  resume: "Shoot to Resume",
  settings: "Settings",
  start: "Start",
}

SIZE_XS = 0
SIZE_SM = 4
SIZE_MD = 6
SIZE_LG = 10

def text(key)
  TEXT.fetch(key)
end

def label(value_or_key, x:, y:, align: ALIGN_LEFT, size: SIZE_MD, color: WHITE)
  text = if value_or_key.is_a?(Symbol)
           text(value_or_key)
         else
           value_or_key
         end

  {
    text: text,
    x: x,
    y: y,
    alignment_enum: align,
    size_enum: size,
  }.merge(color)
end

def collide(args, col1, col2, callback)
  col1 = [col1] unless col1.is_a?(Array)
  col2 = [col2] unless col2.is_a?(Array)

  col1.each do |i|
    col2.each do |j|
      if !i.dead && !j.dead
        if i.intersect_rect?(j)
          callback.call(args, i, j)
        end
      end
    end
  end
end

BULLET_DELAY = 10
BULLET_SIZE = 10
def tick_player(args, player)
  firing = primary_down_or_held?(args.inputs)

  if args.inputs.down
    player.y -= player.speed
    if !firing
      player.direction = DIR_DOWN
    end
  elsif args.inputs.up
    player.y += player.speed
    if !firing
      player.direction = DIR_UP
    end
  end

  if args.inputs.left
    player.x -= player.speed
    if !firing
      player.direction = DIR_LEFT
    end
  elsif args.inputs.right
    player.x += player.speed
    if !firing
      player.direction = DIR_RIGHT
    end
  end

  player.angle = angle_for_dir(player.direction)
  player.bullet_delay += 1

  if player.bullet_delay >= BULLET_DELAY && firing
    player.bullets << {
      x: player.x + player.w / 2 - BULLET_SIZE / 2,
      y: player.y + player.h / 2 - BULLET_SIZE / 2,
      w: BULLET_SIZE,
      h: BULLET_SIZE,
      speed: 12,
      direction: player.direction,
      angle: player.angle,
      dead: false,
      path: Sprite.for(:bullet),
    }.merge(WHITE)
    player.bullet_delay = 0
  end

  player.bullets.each do |b|
    case b.direction
    when DIR_UP
      b.y += b.speed
    when DIR_DOWN
      b.y -= b.speed
    when DIR_LEFT
      b.x -= b.speed
    when DIR_RIGHT
      b.x += b.speed
    end

    if out_of_bounds?(args.grid, b)
      b.dead = true
    end
  end

  player.bullets.reject! { |b| b.dead }

  tick_familiar(args, player)

  debug_label(args, player.x, player.y, "dir: #{player.direction}")
  debug_label(args, player.x, player.y - 14, "angle: #{player.angle}")
  debug_label(args, player.x, player.y - 28, "bullets: #{player.bullets.length}")
end

def tick_familiar(args, player)
  player.familiar ||= {
    x: player.x + 10,
    y: player.y,
    w: 18,
    h: 18,
    path: Sprite.for(:familiar),
  }

  rotator = args.state.tick_count / 18
  fam_dist = 100
  player.familiar.x = player.x + player.w / 2 + Math.sin(rotator) * fam_dist
  player.familiar.y = player.y + player.h / 2 + Math.cos(rotator) * fam_dist
  player.familiar.angle = args.geometry.angle_to(player, player.familiar)
end

def spawn_enemy(args)
  {
    x: [args.grid.left + 10, args.grid.right - 10].sample,
    y: [args.grid.top + 10, args.grid.bottom - 10].sample,
    w: 24,
    h: 24,
    angle: 0,
    path: Sprite.for(:enemy),
    dead: false,
    speed: 3,
  }
end

def tick_enemy(args, enemy)
  enemy.angle = args.geometry.angle_to(enemy, args.state.player)
  enemy.x_vel, enemy.y_vel = vel_from_angle(enemy.angle, enemy.speed)

  enemy.x += enemy.x_vel
  enemy.y += enemy.y_vel

  debug_label(args, enemy.x, enemy.y, "speed: #{enemy.speed}")
end

def tick_exp_chip(args, exp_chip)
  player = args.state.player
  if args.geometry.distance(exp_chip, player) <= player.exp_chip_magnetic_dist
    exp_chip.angle = args.geometry.angle_to(exp_chip, player)
    exp_chip.speed = player.speed + 1
  end

  if exp_chip.speed >= 1
    exp_chip.x_vel, exp_chip.y_vel = vel_from_angle(exp_chip.angle, exp_chip.speed)

    exp_chip.x += exp_chip.x_vel
    exp_chip.y += exp_chip.y_vel
    exp_chip.speed -= 1
  end
end

# +angle+ is expected to be in degrees with 0 being facing right
def vel_from_angle(angle, speed)
  [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
end

def deg_to_rad(deg)
  (deg * Math::PI / 180).round(4)
end

# Returns degrees
def angle_for_dir(dir)
  case dir
  when DIR_RIGHT
    0
  when DIR_LEFT
    180
  when DIR_UP
    90
  when DIR_DOWN
    270
  else
    error("invalid dir: #{dir}")
  end
end

def out_of_bounds?(grid, rect)
  rect.x > grid.right ||
    rect.x + rect.w < grid.left ||
    rect.y > grid.top ||
    rect.y + rect.h < grid.bottom
end

def error(msg)
  raise StandardError.new(msg)
end

PRIMARY_KEYS = [:j, :z]
def primary_down?(inputs)
  PRIMARY_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
    inputs.controller_one.key_down&.a
end
def primary_down_or_held?(inputs)
  primary_down?(inputs) ||
    PRIMARY_KEYS.any? { |k| inputs.keyboard.key_held.send(k) } ||
    (inputs.controller_one.connected &&
     inputs.controller_one.key_held.a)
end

PAUSE_KEYS= [:escape, :p]
def pause_down?(inputs)
  PAUSE_KEYS.any? { |k| inputs.keyboard.key_down.send(k) } ||
    inputs.controller_one.key_down&.start
end

# The version of your game defined in `metadata/game_metadata.txt`
def version
  $gtk.args.cvars['game_metadata.version'].value
end

def title
  $gtk.args.cvars['game_metadata.gametitle'].value
end

def debug?
  @debug ||= !$gtk.production
end

def debug_tick(args)
  return unless debug?

  debug_label(args, args.grid.right - 24, args.grid.top, "#{args.gtk.current_framerate.round}")

  if args.inputs.keyboard.key_down.i
    Sprite.reset_all(args)
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    $gtk.reset
  end

  if args.inputs.keyboard.key_down.zero
    args.state.render_debug_details = !args.state.render_debug_details
  end
end

def debug_label(args, x, y, text)
  return unless debug?
  return unless args.state.render_debug_details

  args.outputs.debug << { x: x, y: y, text: text }.merge(WHITE).label!
end

# Updates and renders a list of options that get passed through.
#
# +options+ data structure:
# [
#   {
#     text: "some string",
#     on_select: -> (args) { "do some stuff in this lambda" }
#   }
# ]
def tick_menu(args, state_key, options)
  args.state.send(state_key).current_option_i ||= 0
  args.state.send(state_key).hold_delay ||= 0
  menu_state = args.state.send(state_key)

  labels = []

  options.each.with_index do |option, i|
    label = label(
      option[:text],
      x: args.grid.w / 2,
      y: 360 + (options.length - i * 52),
      align: ALIGN_CENTER,
      size: SIZE_MD
    )
    label_size = args.gtk.calcstringbox(label.text, label.size_enum)
    labels << label
    if menu_state.current_option_i == i
      args.outputs.solids << {
        x: label.x - (label_size[0] / 1.4) - 24 + (Math.sin(args.state.tick_count / 8) * 4),
        y: label.y - 22,
        w: 16,
        h: 16,
      }.merge(WHITE)
    end
  end

  args.outputs.labels << labels

  move = nil
  if args.inputs.down
    move = :down
  elsif args.inputs.up
    move = :up
  else
    menu_state.hold_delay = 0
  end

  if move
    menu_state.hold_delay -= 1

    if menu_state.hold_delay <= 0
      index = menu_state.current_option_i
      if move == :up
        index -= 1
      else
        index += 1
      end

      if index < 0
        index = options.length - 1
      elsif index > options.length - 1
        index = 0
      end
      menu_state.current_option_i = index
      menu_state.hold_delay = 10
    end
  end

  if primary_down?(args.inputs)
    options[menu_state.current_option_i][:on_select].call(args)
  end
end
