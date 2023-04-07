def play_sfx(args, key)
  if args.state.setting.sfx
    args.audio["sfx_#{key}"] = {
      input: "sounds/#{key}.wav",
      gain: 0.6,
    }
  end
end
