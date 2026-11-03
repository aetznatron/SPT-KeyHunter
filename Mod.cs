using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using SPTarkov.DI.Annotations;
using SPTarkov.Server.Core.Services;
using SPTarkov.Server.Core.DI;
using SPTarkov.Server.Core.Models.Spt.Mod;
using SPTarkov.Server.Core.Models.Spt.Tables;
using KeyHunter.Config;
using KeyHunter.Services;
using SemanticVersioning;
using Version = SemanticVersioning.Version;
using Range = SemanticVersioning.Range;

namespace KeyHunter
{
    public sealed record KeyHunterModMetadata : IModMetadata
    {
        public string ModGuid { get; init; }  = "com.keyhunter.spt40";
        public string Name { get; init; } = "KeyHunter";
        public string Author { get; init; } = "miXXed";
        public Version Version { get; init; } = new("2.1.0");
        public string? Url { get; init; } = "https://github.com/miXXed234/SPT-KeyHunter";
        public Range SptVersion { get; init; } = new("~4.1");
        public string License { get; init; } = "MIT";
        public bool HasPrepatcher { get; init; } = false;
        public List<string>? Contributors { get; init; } = new() { "MusicManiac (Original Mod)" };
        public List<string>? Incompatibilities { get; init; } = new();
        public Dictionary<string, Range>? ModDependencies { get; init; } = new();
    }

    public static class KeyHunterLoadPriority
    {
        public const int KeyHunterPriorityOffset = 1000;
    }

    [Injectable(TypePriority = OnLoadOrder.Preload + KeyHunterLoadPriority.KeyHunterPriorityOffset)]
    public class Mod : IOnLoad
    {
        private readonly ConfigService _configService;
        private readonly LootPatchService _lootPatchService;
        private readonly PriceAdjustmentService _priceAdjustmentService;
        private readonly ILogger<Mod> _logger;

        public Mod(
            ConfigService configService,
            LootPatchService lootPatchService,
            PriceAdjustmentService priceAdjustmentService,
            ILogger<Mod> logger
        )
        {
            _configService = configService;
            _lootPatchService = lootPatchService;
            _priceAdjustmentService = priceAdjustmentService;
            _logger = logger;
        }

        public Task OnLoadAsync(CancellationToken cancellationToken)
        {
            try
            {
                var config = _configService.Load();
                
                if (!config.Enabled)
                {
                    _logger.LogInformation("[KeyHunter] Mod is disabled in config");
                    return Task.CompletedTask;
                }

                // Log config status only when debug logging is enabled
                if (config.DebugLogging)
                {
                    var configStatus = $"debugLogging={config.DebugLogging}";
                    if (config.ForcedPlayerLevel.HasValue && config.ForcedPlayerLevel.Value > 0)
                    {
                        configStatus += $", forcedPlayerLevel={config.ForcedPlayerLevel.Value}";
                    }
                    _logger.LogInformation("[KeyHunter] Config: {Status}", configStatus);
                }

                _priceAdjustmentService.AdjustPrices();
                _lootPatchService.OnPostDBLoad();

                _logger.LogInformation("[KeyHunter] v2.1.0 loaded successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[KeyHunter] Error during initialization");
            }

            return Task.CompletedTask;
        }
    }
}
