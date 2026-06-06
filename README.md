# Odysseus Windows Launcher

One-click Windows launcher for Odysseus that starts the local app, waits for it to become ready, and opens Chrome directly to the login page.

## What It Does

- Checks whether Odysseus is already running at `http://127.0.0.1:7000/login`.
- Starts Odysseus with the app's local virtual environment if needed.
- Waits until the login page responds.
- Opens Chrome to the Odysseus login page.
- Falls back to the default browser if Chrome is not installed.

## Files

- `Start-Odysseus.ps1` - PowerShell launcher script.
- `odysseus.ico` - Optional desktop shortcut icon.

## Requirements

- Windows PowerShell 5.1 or newer.
- A native Windows Odysseus install with:
  - `app.py`
  - `venv\Scripts\python.exe`
- Chrome is optional. If Chrome is missing, the script opens the login URL with the default browser.

## Recommended Install

Copy these two files into your Odysseus folder:

```text
odysseus\
  launcher-assets\
    Start-Odysseus.ps1
    odysseus.ico
```

With that layout, the launcher automatically treats the parent `odysseus` folder as the app root.

## Test The Launcher

From PowerShell:

```powershell
cd C:\path\to\odysseus
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher-assets\Start-Odysseus.ps1
```

If your script lives somewhere else, pass the Odysseus path explicitly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\path\to\Start-Odysseus.ps1 -AppRoot C:\path\to\odysseus
```

## Create A Desktop Shortcut

Update `$OdysseusRoot` if your install lives somewhere else, then run this in PowerShell:

```powershell
$OdysseusRoot = "C:\path\to\odysseus"
$ShortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Odysseus.lnk"
$ScriptPath = Join-Path $OdysseusRoot "launcher-assets\Start-Odysseus.ps1"
$IconPath = Join-Path $OdysseusRoot "launcher-assets\odysseus.ico"
$PowerShellPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

$Wsh = New-Object -ComObject WScript.Shell
$Shortcut = $Wsh.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $PowerShellPath
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
$Shortcut.WorkingDirectory = $OdysseusRoot
$Shortcut.IconLocation = "$IconPath,0"
$Shortcut.Description = "Start Odysseus and open Chrome to the login page"
$Shortcut.Save()
```

Double-click the new `Odysseus` desktop shortcut to start the app and open:

```text
http://127.0.0.1:7000/login
```

## Options

Use a different port:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher-assets\Start-Odysseus.ps1 -Port 7001
```

Start Odysseus without opening a browser:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\launcher-assets\Start-Odysseus.ps1 -NoBrowser
```

Use a script outside the Odysseus folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\tools\Start-Odysseus.ps1 -AppRoot C:\path\to\odysseus
```

## Notes

- This script does not install Odysseus, Python dependencies, Ollama, or local models.
- It assumes Odysseus has already been set up once and has a working `venv`.
- Logs from launcher-started runs are written to the Odysseus `logs` folder.
- Keep `.env`, `data`, `logs`, `venv`, and any generated auth files out of Git.
