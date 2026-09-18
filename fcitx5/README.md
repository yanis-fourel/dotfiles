# Fcitx5

The main `config` and addon `conf/*.conf` files are shared. The generated
`conf/cached_layouts` and live `profile` are ignored: Fcitx5 rewrites them,
and the profile mixes input-method configuration with mutable selection state.

`profile.example` preserves the input-method list for new installations.
After installing with Stow, quit Fcitx5 and initialize the profile only if it
is missing:

```sh
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5"
if [ ! -e "$config_dir/profile" ]; then
    cp "$config_dir/profile.example" "$config_dir/profile"
fi
```

Then restart Fcitx5. To share intentional input-method changes, manually update
`profile.example`; changes to the live profile remain local.
