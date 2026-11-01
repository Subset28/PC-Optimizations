// Starts the watcher with no console window. Scheduled task runs: wscript.exe //B //Nologo run-hidden.js
// (VBScript is not installed on Windows 11 25H2 by default, so this uses JScript.)
var fso = new ActiveXObject("Scripting.FileSystemObject");
var dir = fso.GetParentFolderName(WScript.ScriptFullName);
var sh = new ActiveXObject("WScript.Shell");
sh.Run('powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + dir + '\overwolf-on-valorant.ps1"', 0, false);
