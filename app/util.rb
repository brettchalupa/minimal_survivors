###########
# utility, math, and misc methods below

# returns random val between min & max, inclusive
# needs integers, use rand if you don't need min/max and don't care much
def random(min, max)
  min = Integer(min)
  max = Integer(max)
  rand((max + 1) - min) + min
end

# returns true the passed in % of the time
# ex: `percent_chance?(25)` -- 1/4 chance of returning true
def percent_chance?(percent)
  error("percent param (#{percent}) can't be above 100!") if percent.to_f > 100.0
  return false if percent.to_f == 0.0
  return true if percent.to_f == 100.0
  rand() < (percent / 100.0)
end

# strips away the junk added by GTK::OpenEntity
def open_entity_to_hash(open_entity)
  open_entity.as_hash.except(:entity_id, :entity_name, :entity_keys_by_ref, :__thrash_count__)
end

# Executes the block for each intersection of the collections. Doesn't check
# intersections within a parameter
#
# Block arguments are an instance of each collection, ordered by the parameter
# order.
#
# ex:
# collide(tiles, enemies) do |tile, enemy|
#   # do stuff!
# end
#
# collide(player, enemies) do |player, enemy|
#   player.health -= enemy.power
# end
def collide(col1, col2, &block)
  col1 = [col1] unless col1.is_a?(Array)
  col2 = [col2] unless col2.is_a?(Array)

  col1.each do |i|
    col2.each do |j|
      if i.intersect_rect?(j)
        block.call(i, j)
      end
    end
  end
end

# +angle+ is expected to be in degrees with 0 being facing right
def vel_from_angle(angle, speed)
  [speed * Math.cos(deg_to_rad(angle)), speed * Math.sin(deg_to_rad(angle))]
end

# returns diametrically opposed angle
# uses degrees
def opposite_angle(angle)
  add_to_angle(angle, 180)
end

# returns a new angle from the og `angle` one summed with the `diff`
# degrees! of course
def add_to_angle(angle, diff)
  ((angle + diff) % 360).abs
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

# checks if the passed in `rect` is outside of the `container`
# `container` can be any rectangle-ish data structure
def out_of_bounds?(container, rect)
  rect.x > container.right ||
    rect.x + rect.w < container.left ||
    rect.y > container.top ||
    rect.y + rect.h < container.bottom
end

def error(msg)
  raise StandardError.new(msg)
end

# The version of your game defined in `metadata/game_metadata.txt`
def version
  $gtk.args.cvars['game_metadata.version'].value
end

def title
  $gtk.args.cvars['game_metadata.gametitle'].value
end

# debug mode is what's running when you're making the game
# when you build and ship your game, it's in production mode
def debug?
  @debug ||= !$gtk.production
end

# render a label that is only shown when in debug mode and the debug details
# are shown; toggle with +0+ key
def debug_label(args, x, y, text)
  return unless debug?
  return unless args.state.render_debug_details

  args.outputs.debug << { x: x, y: y, text: text }.merge(WHITE).label!
end

# sets the passed in entity's color for the specified number of ticks
def flash(entity, color, tick_count)
  entity.flashing = true
  entity.flash_ticks_remaining = tick_count
  entity.flash_color = color
end

def tick_flasher(entity)
  if entity.flashing
    entity.flash_ticks_remaining -= 1
    entity.merge!(entity.flash_color)
    if entity.flash_ticks_remaining <= 0
      entity.flashing = false
      reset_color(entity)
    end
  end
end

def reset_color(entity)
  entity.a = nil
  entity.r = nil
  entity.g = nil
  entity.b = nil
end

# different than background_color... use this to change the bg color!
def draw_bg(args, color)
  args.outputs.solids << { x: args.grid.left, y: args.grid.bottom, w: args.grid.w, h: args.grid.h }.merge(color)
end
