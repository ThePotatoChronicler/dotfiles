# PotatoChronicler's Dotfiles

These are my dotfiles, there are many like them, but these ones are mine!

## Containers

A set of images is available as a devbox, containing these dotfiles<br>
+ The fish config contains a script to quickly start these up!

### Available images

- base: Contains the editor and some basics, all other images build up from this one
- javascript: For JS/TS development

### Running a container

To quickly start up one, this command might prove useful:

```bash
podman run \
    -ti \
    --env TERM \
    --env COLORTERM \
    -- \
    "codeberg.org/potatochronicler/dotfiles/containers/base:latest"
```

This is basically a worse version of the `box` command from the config.
