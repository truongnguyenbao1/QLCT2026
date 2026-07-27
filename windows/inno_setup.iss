[Setup]
AppName=TroKeeper
AppVersion={#MyAppVersion}
AppPublisher=TroKeeper Team
AppPublisherURL=https://trokeeper.tnb.io.vn
AppSupportURL=https://trokeeper.tnb.io.vn
AppUpdatesURL=https://github.com/truongnguyenbao1/QLCT2026/releases
DefaultDirName={autopf}\TroKeeper
DefaultGroupName=TroKeeper
DisableProgramGroupPage=yes
OutputBaseFilename=TroKeeper_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\trokeeper.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\TroKeeper"; Filename: "{app}\trokeeper.exe"
Name: "{autodesktop}\TroKeeper"; Filename: "{app}\trokeeper.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\trokeeper.exe"; Description: "{cm:LaunchProgram,TroKeeper}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCR; Subkey: "io.supabase.flutter"; ValueType: string; ValueName: ""; ValueData: "URL:Supabase OAuth Protocol"; Flags: uninsdeletekey
Root: HKCR; Subkey: "io.supabase.flutter"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: uninsdeletekey
Root: HKCR; Subkey: "io.supabase.flutter\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\trokeeper.exe,0"; Flags: uninsdeletekey
Root: HKCR; Subkey: "io.supabase.flutter\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\trokeeper.exe"" ""%1"""; Flags: uninsdeletekey
