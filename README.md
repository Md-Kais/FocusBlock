# FocusBlock

A lightweight command-line URL blocking tool for Debian Linux. Block distracting websites by category, set a timer so blocks lift automatically, and switch between blocking modes on the fly — all from a single command.

---

## Background & Motivation

Not long ago, I found myself doing something that, in hindsight, was almost comical in how automatic it had become. I would open my browser, type the letters *"IN"* into the address bar — and before a single conscious thought could intervene, Instagram would surface as the first suggestion. I would click it. I would scroll. Ten minutes would pass, sometimes thirty, sometimes more. Then I would close the tab, feel a vague dissatisfaction, and return to whatever I was supposed to be doing — only to repeat the entire sequence an hour later without even realising it.

The troubling part was not the time lost. It was the absence of a decision. There was no moment where I thought *"I want to use Instagram right now."* The muscle memory had simply bypassed the mind entirely.

Now, the common wisdom here is to say: *fix your mindset*. And that is true — mindset is the foundation of everything. But mindset alone is a fragile shield against a habit that has become chronic and reflexive. Willpower is a finite resource, and it runs thinnest precisely at the moments you need it most — when you are tired, bored, or mentally adrift.

The philosophy behind FocusBlock is not to solve the problem for you. It will not cure mindless doomscrolling. It will not rewire your dopamine pathways or make you a more disciplined person overnight. What it does is far more modest, and perhaps more honest: **it creates an obstacle**. A small, deliberate friction between impulse and action. A speed bump that gives the conscious mind a fraction of a second to catch up with the reflexive one.

That half-second — the moment where you type "IN," hit Enter, and see a blocked page instead of a feed — is the entire point. It is not a wall. It is a pause. And sometimes a pause is all it takes to step back, rethink, and choose differently.

---

## Future Plans

FocusBlock is, at present, a lean and purposeful tool. But there is more ground to cover. The following features are planned for future releases:

**1. History Log** — A record of every time blocking was activated or deactivated, with timestamps. So you can look back honestly at the shape of your habits and see the patterns you might otherwise prefer not to confront.

**2. Attempt Counter** — A count of how many times the user has invoked FocusBlock across its lifetime. There is something quietly clarifying about a number that simply tells you: *you have needed this 47 times.* No judgment — only honesty.

**3. Block Event Tracking** — A tally of how many individual website access attempts were intercepted by the script. Not just how many times you blocked, but how many times the block actually held the line.

**4. And more** — Scheduled blocking windows (e.g. block automatically every morning from 09:00 to 12:00), per-site custom additions from the command line, a lock mode that prevents unblocking until the timer expires, and a minimal status indicator suitable for shell prompts and status bars.

The core of this tool will always remain simple. Complexity is, after all, its own kind of distraction.

---

## Requirements

- Debian 13 (or any Debian-based distro)
- Bash
- Root / sudo access

No external dependencies. Everything runs on standard Linux utilities.

---

## Installation

Download `focusblock.sh` and `install.sh` into the same folder, then run:

```bash
sudo bash install.sh
```

This will:
- Install `focusblock` to `/usr/local/bin` (available system-wide)
- Create the state directory at `/var/lib/focusblock`
- Back up your original `/etc/hosts` to `/var/lib/focusblock/hosts.backup`

---

## Categories

| # | Name | Blocks |
|---|------|--------|
| `1` | Social + Porn | Facebook, Instagram, Threads, Twitter/X, browser game sites, and porn sites |
| `2` | Full Focus | Everything in Category 1, plus YouTube |
| `3` | Porn Only | Porn sites only |

<details>
<summary>Full site list</summary>

**Social Media**
`facebook.com`, `instagram.com`, `threads.net`, `twitter.com`, `x.com`

**Browser Games**
`kongregate.com`, `poki.com`, `miniclip.com`, `crazygames.com`, `y8.com`, `addictinggames.com`

**Porn**
`pornhub.com`, `xvideos.com`, `xhamster.com`, `redtube.com`, `youporn.com`, `xnxx.com`, `brazzers.com`, `onlyfans.com`, `chaturbate.com`, `livejasmin.com`, `cam4.com`, `stripchat.com`, `spankbang.com`, `eporner.com`, `tube8.com`, `tnaflix.com`, `drtuber.com`, `beeg.com`, `nhentai.net`, `rule34.xxx`

**YouTube** *(Category 2 only)*
`youtube.com`, `youtu.be`, `youtube-nocookie.com`

Both `www.` and bare domain variants are blocked for all sites, along with mobile subdomains where applicable.
</details>

---

## Commands

### Block a category

```bash
sudo focusblock block <1|2|3>
```

Blocks the chosen category indefinitely until you manually unblock.

```bash
sudo focusblock block 1    # Social media + porn
sudo focusblock block 2    # Everything + YouTube
sudo focusblock block 3    # Porn only
```

### Block with a timer

```bash
sudo focusblock block <1|2|3> --for <duration>
```

Blocks the category and automatically lifts the block when the timer expires. The timer runs in the background — you can close your terminal and it will still unblock on time.

```bash
sudo focusblock block 1 --for 2h       # 2 hours
sudo focusblock block 2 --for 30m      # 30 minutes
sudo focusblock block 3 --for 1h30m    # 1 hour 30 minutes
sudo focusblock block 1 --for 90m      # 90 minutes
sudo focusblock block 2 --for 45s      # 45 seconds
```

**Duration format:** combine `h` (hours), `m` (minutes), `s` (seconds) in any combination. A plain number with no suffix is treated as seconds.

### Switch category

```bash
sudo focusblock switch <1|2|3>
```

Instantly switches to a different blocking category. If a timer is already running, it is preserved and keeps counting down. To reset the timer at the same time:

```bash
sudo focusblock switch 2 --for 1h
```

### Unblock everything

```bash
sudo focusblock unblock
```

Removes all blocks and clears any active timer.

### Check status

```bash
focusblock status
```

Shows the active category, timer countdown, and the time blocking ends. Does not require root.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       FocusBlock Status

  Status:   ● ACTIVE
  Blocking: Category 2 — Social + Porn + YouTube
  Timer:    ⏱  1h 23m 45s remaining
  Ends at:  14:30:00 on Mar 14
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Check timer only

```bash
focusblock timer
```

Prints just the time remaining on the active timer. Does not require root. Useful for a quick check without the full status output.

### Help

```bash
focusblock help
```

---

## Examples

```bash
# Start a deep work session — block everything for 2 hours
sudo focusblock block 2 --for 2h

# Check how much time is left
focusblock timer

# Realized you need YouTube — switch to category 1 (keeps timer)
sudo focusblock switch 1

# Done early — remove all blocks
sudo focusblock unblock

# Evening routine — just block porn indefinitely
sudo focusblock block 3
```

---

## How It Works

FocusBlock redirects blocked domains to `127.0.0.1` (your local machine) by writing entries to `/etc/hosts`. When you try to visit a blocked site, your browser gets sent nowhere.

- **Blocking** appends a clearly marked section to `/etc/hosts` between `# === FOCUSBLOCK START ===` and `# === FOCUSBLOCK END ===` markers.
- **Unblocking** removes only that section, leaving the rest of your `/etc/hosts` untouched.
- **DNS flushing** is done automatically after every change via `resolvectl` so blocks take effect immediately without needing a reboot or browser restart.
- **Timer** runs as a background process (detached from the terminal) and cleans up `/etc/hosts` when it expires. Timer expiry is also logged to syslog via `logger`.
- **State** is tracked in `/var/lib/focusblock/state` and `/var/lib/focusblock/timer` as plain text files.

---

## File Locations

| Path | Purpose |
|------|---------|
| `/usr/local/bin/focusblock` | The installed script |
| `/var/lib/focusblock/state` | Currently active category |
| `/var/lib/focusblock/timer` | Timer end time (Unix timestamp) |
| `/var/lib/focusblock/hosts.backup` | Backup of your original `/etc/hosts` |

---

## Restoring Your Hosts File

Your original `/etc/hosts` is backed up automatically on first install. To restore it:

```bash
sudo cp /var/lib/focusblock/hosts.backup /etc/hosts
```

Or just run `sudo focusblock unblock` which removes FocusBlock's entries cleanly without touching the rest of the file.

---

## Adding Custom Sites

Open `focusblock.sh` and add domains to the appropriate array near the top of the file (`SOCIAL_MEDIA_SITES`, `PORN_SITES`, or `YOUTUBE_SITES`), then reinstall:

```bash
sudo bash install.sh
```

Changes take effect the next time you run `block` or `switch`.

---

## Limitations

- Blocks are applied system-wide (all browsers, all users on the machine).
- Does not block apps that bypass the system hosts file or use hardcoded DNS servers (e.g. some VPN clients).
- If the system is rebooted while a timer is running, the timer daemon is lost — but the block in `/etc/hosts` remains active. Run `sudo focusblock unblock` to remove it manually, or `sudo focusblock block <cat> --for <time>` to restart with a new timer.
- Not a substitute for a firewall. A determined user with root access can remove blocks by editing `/etc/hosts` directly.