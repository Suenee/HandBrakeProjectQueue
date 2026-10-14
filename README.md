# HandBrake Project Queue

Windows .NET 10 WinForms helper for finding project videos and opening selected sources in HandBrake. Current version: **0.10**.

## Run

Run `run.cmd` after installing with `upgrade.cmd`.

## Application icon

Place the transparent PNG at `assets/HBPQ.png` in your local checkout. During `upgrade.cmd`, `scripts/Build-Icon.ps1` converts it to a multi-resolution `assets/HBPQ.ico` (16–256 px), and the .NET publish step embeds that icon into the EXE. The source PNG is not modified. The generated ICO is ignored by Git. If the PNG and ICO are both absent, the updater reports a warning and builds without a custom icon.

**Note:** A PNG that exists only in a local checkout is not automatically uploaded to GitHub by the updater. Commit it separately if the source asset should be distributed to other installations.

## HandBrake integration

Selected videos are passed to HandBrake's Windows GUI as source arguments. Direct external insertion into the native GUI encoding queue is not yet implemented or guaranteed.

## Configuration and logging

Settings are available from the File menu. Czech and English UI resources are built in. Logging supports `off`, `single`, and `all`. See `config.example.json` for configuration fields.

## Upgrade

Run `upgrade.cmd` from the checkout (including mapped/network drives). GitHub main is authoritative. The updater backs up recoverable local Git history and tracked changes to logs/git-recovery-* when necessary, exits an interrupted rebase, and synchronizes the checkout to origin/main. It does not push local commits. It builds in staging, preserves existing configuration during deployment, and writes `logs/upgrade.log`.
