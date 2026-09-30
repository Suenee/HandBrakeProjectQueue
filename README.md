# HandBrake Project Queue

Windows project-aware helper for HandBrake. Version 0.01.

HBPQ scans the Suenee Universe EDITING project tree and each project's DELIVERY folder. The default project list contains projects with at least one source video without its matching `-conv.mp4` output, sorted Z-A. The editable project selector searches all project directories, including completed projects. After project selection, source videos are shown as checkboxes; converted output files are never offered as inputs. Pending files are checked by default, while already converted sources remain available for an intentional re-encode.

## HandBrake integration

HandBrake documents importing GUI-exported queue files into HandBrakeCLI, but does not document a public interface for injecting new jobs into an already running Windows GUI queue. Version 0.01 therefore keeps queue submission behind `src/HandBrakeIntegration.ps1` and does not modify HandBrake private queue/state files. The selection workflow is implemented; native GUI queue submission remains isolated until a supported or separately verified adapter is chosen.

## Run

Run `run.cmd`.

## Configuration

Copy `config.example.json` to `config.local.json` only for local overrides. Local, mapped, and network storage are supported design targets.

## Upgrade

Run `upgrade.cmd`. The updater follows the Wipe Codes upgrade protocol and writes `logs\\upgrade.log`.
