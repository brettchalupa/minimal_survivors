# Minimal Survivors

**A 2D action shooter prototype by Brett Chalupa**

Inspired by _Vampire Survivors_ and the like. Made over the course of a week. The starting point for the experimental Exquisite Corps jam by the DragonRuby Game Toolkit community.

_Minimal Survivors_ is dedicated to the public domain.

Built with DragonRuby Game Toolkit v3.24 Pro Edition (uses Standard features in the code but uses the Pro high DPI and bytecode features).

## Controls

- Move: WASD / Arrow Keys / Gamepad
- Select & Fire: J / Z / Space / Gamepad A button

## Developing

The engine files are not included in this source repository so that people can use whatever operating system they want. Also, if we open source it when it's done, it's easier to not have to deal with that.

1. Unzip the DragonRuby Game Toolkit engine zip
2. Delete the `mygame` directory
3. Clone the repository into the DRGTK engine folder with the folder name `mygame`: `git clone git@github.com:brettchalupa/minimal_survivors.git mygame`
4. Start DragonRuby, and make it awesome!

### On the Code Architecture

The code is intentionally structured to make use of functions and `args.state` without any classes. A functional-ish approach. This follows in the spirit of DRGTK's docs.

### Keyboard Shortcuts

There following debug-only shortcuts can be used to help make developing easier:

- <kbd>i</kbd> -- reload the sprites from disk
- <kbd>r</kbd> -- reset the game
- <kbd>0</kbd> -- render debug details
- <kbd>1</kbd> -- level up player
- <kbd>2</kbd> -- toggle player invincibility

### Tests

Tests for methods live in `app/tests.rb`. Run the tests with from within your engine dir with:

``` console
./dragonruby mygame --eval mygame/app/tests.rb --no-tick --exit-on-fail
```

or just use `./run_tests` if you're on an OS with shell scripting (Linux/MacOS).
