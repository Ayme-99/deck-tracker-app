; Script de Inno Setup para empaquetar el build de Windows de Deck Tracker
; en un instalador unico (DeckTrackerSetup-X.Y.Z+N.exe), como los que se
; suben a cada release de GitHub.
;
; Uso:
;   1. flutter build windows --release   (desde la raiz del repo)
;   2. Actualiza MyAppVersion abajo para que coincida con pubspec.yaml
;   3. Compila este script con Inno Setup (ISCC.exe deck_tracker.iss, o
;      abrelo en el IDE de Inno Setup y pulsa Compilar)
;   4. El .exe resultante sale en windows_installer\output\

#define MyAppName "Deck Tracker"
#define MyAppVersion "1.3.0+1"
#define MyAppPublisher "Ayme-99"
#define MyAppExeName "deck_tracker_app.exe"
#define MyAppId "{{B7A2C9E4-5F3D-4A1B-9C6E-8D2F1A0B3C7E}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=DeckTrackerSetup-{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

; Copia TODO el contenido de build\windows\x64\runner\Release (exe + dlls +
; carpeta data) -- el runner de Flutter necesita todo eso junto para arrancar.
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
