function Write-IcingaPluginPerfData()
{
    param(
        $PerformanceData,
        $CheckCommand
    );

    if ($PerformanceData.package -eq $FALSE) {
        $PerformanceData = @{
            $PerformanceData.label = $PerformanceData;
        }
    } else {
        $PerformanceData = $PerformanceData.perfdata;
    }

    $CheckResultCache = Get-IcingaCacheData -Space 'sc_daemon' -CacheStore 'checkresult' -KeyName $CheckCommand;

    if ($global:IcingaDaemonData.FrameworkRunningAsDaemon -eq $FALSE) {
        [string]$PerfDataOutput = (Get-IcingaPluginPerfDataContent -PerfData $PerformanceData -CheckResultCache $CheckResultCache);
        Write-IcingaConsolePlain ([string]::Format('| {0}', $PerfDataOutput));
    } else {
        [void](Get-IcingaPluginPerfDataContent -PerfData $PerformanceData -CheckResultCache $CheckResultCache -AsObject $TRUE);
    }
}

function Get-IcingaPluginPerfDataContent()
{
    param(
        $PerfData,
        $CheckResultCache,
        [bool]$AsObject = $FALSE
    );

    [string]$PerfDataOutput = '';

    foreach ($package in $PerfData.Keys) {
        $data = $PerfData[$package];
        if ($data.package) {
            $PerfDataOutput += (Get-IcingaPluginPerfDataContent -PerfData $data.perfdata -CheckResultCache $CheckResultCache -AsObject $AsObject);
        } else {
            foreach ($checkresult in $CheckResultCache.PSobject.Properties) {
                $SearchPattern = [string]::Format('{0}_', $data.label);
                $SearchEntry   = $checkresult.Name;
                if ($SearchEntry -like "$SearchPattern*") {
                    $cachedresult = (New-IcingaPerformanceDataEntry -PerfDataObject $data -Label $SearchEntry -Value $checkresult.Value);

                    if ($AsObject) {
                        # New behavior with local thread separated results
                        $global:Icinga.PerfData += $cachedresult;
                    }
                    $PerfDataOutput += $cachedresult;
                }
            }

            $compiledPerfData = (New-IcingaPerformanceDataEntry $data);

            if ($AsObject) {
                # New behavior with local thread separated results
                $global:Icinga.PerfData += $compiledPerfData;
            }
            $PerfDataOutput += $compiledPerfData;
        }
    }

    return $PerfDataOutput;
}

Export-ModuleMember -Function @( 'Write-IcingaPluginPerfData' );
