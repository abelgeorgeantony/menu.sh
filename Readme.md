# menu.sh

`menu.sh` is a lightweight menu and launcher for text-mode consoles.
Menus are described with YAML and sub-menus are supported.

https://github.com/iandennismiller/menu.sh

## Quickstart

1. Use `#!/usr/bin/env menu.sh` as the shebang for a YAML file
2. Make the YAML file executable with `chmod u+x my.menu.yaml`
3. Now it's a menu! Run it like a script: `./my.menu.yaml`

### Example

This example demonstrates a menu containing two sub-menus: apps and system.

```yaml
#!/usr/bin/env menu.sh
---
apps:
  start-x-windows:
    run: startx
  ssh-to-work:
    run-wait: ssh -t my.host.example.org.co '/bin/sh echo I always forget this hostname'
system:
  shutdown:
    run: sudo shutdown now
  reboot:
    run: sudo reboot
  logout:
    run: logout
```

## Installation

```bash
wget https://github.com/iandennismiller/menu.sh/raw/refs/heads/main/menu.sh
install -C -v ./menu.sh ~/.local/bin/menu.sh
```

### yq is required

https://github.com/mikefarah/yq

### fzf is required

https://github.com/junegunn/fzf

## Why use a console launcher

Menus offer good discoverability of the available commands. Sometimes I forget all the available choices and a menu can act like documentation to remind me.

Menus capture useful launch profiles so that common actions are easier to perform. Some commands are very specific and it's annoying to type them repeatedly.

I want a console-based launcher for my cyberdeck, which has a tiny keyboard. I want to stay in the console to extend battery time and I sometimes want to launch apps with a few key presses.

## Usage

### Describing a menu item

```yaml
#!/usr/bin/env menu.sh
---
this-appears-in-menu:
  run: echo "this command runs when launched"
```

### Menus can be nested

```yaml
#!/usr/bin/env menu.sh
---
ssh:
  __cmd__: autossh -M 0 -t $1 "/bin/bash -c 'tmux new-session -A -s main'"
  host1:
    cmd: host1.full.hostname
  host2:
    cmd: host2.full.hostname
  host3-is-different:
    run: autossh -M 0 -J proxy-host -t host3.full.hostname "/bin/bash -c 'tmux new-session -A -s main'"
vpn:
  roam-start:
    run: sudo systemctl stop wg-quick@wg0 && sudo systemctl start wg-quick@roam
  roam-stop:
    run: sudo systemctl stop wg-quick@roam && sudo systemctl start wg-quick@wg0
system:
  shutdown:
    run: sudo shutdown now
  reboot:
    run: sudo reboot
  logout:
    run: logout
```

### Including other menus

```yaml
#!/usr/bin/env menu.sh
---
ssh:
  run: ./examples/cmd-macro.menu.yaml
vpn:
  run: ./examples/vpn.menu.yaml
system:
  run: ./examples/system.menu.yaml
```

### `run` and `run-wait`

When a menu item has `run-wait`, the console will wait for you to press enter once it's completed.

### The `__cmd__` macro and `cmd`

Sometimes, menus repeat similar commands with minor variations.
`menu.sh` supports this pattern with the `__cmd__` macro, which enables menu items to share a launch method.
Once `__cmd__` has been specified, it can be used with `cmd`, similar to the way `run` works.

```yaml
#!/usr/bin/env menu.sh
---
__cmd__: autossh -M 0 -t $1 "/bin/bash -c 'tmux new-session -A -s main'"
host1:
  cmd: host1.full.hostname
host2:
  cmd: host2.full.hostname
host3-is-different:
  run: autossh -M 0 -J proxy-host -t host3.full.hostname "/bin/bash -c 'tmux new-session -A -s main'"
```
