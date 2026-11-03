# Building SPT-KeyHunter against SPT 4.1.x

Server mod, one SDK-style project. Unlike the game-DLL style projects, this one
consumes SPT as **NuGet packages**, so no local assembly paths are needed.

## Requirements

* .NET 10 SDK (`winget install Microsoft.DotNet.SDK.10`) — SPT 4.1.x runs on .NET 10
* Internet access for the NuGet restore of `SPTushonka.Server.Core`
* SPT 4.1.x installation for the deployment target

## Packages

```xml
<TargetFramework>net10.0</TargetFramework>
<PackageReference Include="SPTushonka.Server.Core" Version="4.1.6" />
<PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="10.0.9" />
```

Since 4.1.3 the SPT packages are published as `SPTushonka.*` (assemblies and
namespaces stay `SPTarkov.*`). The logging package version must not be lower than
what `SPTushonka.DI` pulls in transitively, otherwise the restore fails with
`NU1605` (package downgrade) — 10.0.9 matches the .NET 10 dependency chain.

## Build and install

```
powershell -ExecutionPolicy Bypass -File build-spt.ps1
```

Options: `-Package` (writes `build\KeyHunter-v<version>.zip`), `-SkipDeploy`.
Refuses to deploy while `SPT.Server` is running; an existing
`Config\config.json` is never overwritten.

## Install layout (SPT 4.1.x)

```
SPT_Runtime\user\mods\KeyHunter\
├── KeyHunter.dll
└── Config\config.json
```

`ConfigService` looks for `<mod>\Config\config.json`, then `<mod>\config.json`,
then `<parent>\Config\config.json`, and falls back to built-in defaults with a
warning if none exists.

## SPT 4.1 API notes for this port

| 4.0 | 4.1 |
| --- | --- |
| `AbstractModMetadata` (+ `IsBundleMod`) | `IModMetadata` (+ `HasPrepatcher`) |
| `Task OnLoad()` | `Task OnLoadAsync(CancellationToken)` |
| `OnLoadOrder.PostDBModLoader` | `OnLoadOrder.Preload` for database/loot-table work |
| `DatabaseService.GetItems()` | `templateTable.Items` |
| `DatabaseService.GetHandbook()` | `templateTable.Handbook` |
| `DatabaseService.GetLocations()` | `locationTable` (`GetDictionary()` / `GetLocation(id)`) |
| `SPTarkov.Server.Core` package | `SPTushonka.Server.Core` package |

`Microsoft.Extensions.Logging.ILogger<T>` is still resolvable from DI in 4.1.6,
so the existing logging code needs no change.
