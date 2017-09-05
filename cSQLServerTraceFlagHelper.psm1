function Get-SQLTraceFlag
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    Param
    (
        [Parameter(Mandatory = $true,
                   Position = 1)]
        [System.String]           
        $SQLInstanceName
    )

    Initialize-SQLSMOAssembly
    $SQLManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $WMIService = $SQLManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }
    $ParameterList = $WMIService.StartupParameters.Split(';')
    $ParameterList | Where-Object -FilterScript { $PSItem -like '-T*' } | ForEach-Object {
        $PSItem.TrimStart('-')
    }
}

function Set-SQLTraceFlag
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 1)]
        [System.String]
        $SQLInstanceName = 'MSSQLServer',

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [System.String[]]
        $TraceFlag,

        [switch]
        $RestartSQLService
    )

    Initialize-SQLSMOAssembly
    $sqlManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $wmiService = $sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }

    # Add '-' dash to flag
    $traceFlagList = $TraceFlag | ForEach-Object {
        "-$PSItem"
    }

    # Extract flags from startup parameters
    [System.Collections.ArrayList]$parameterList = $wmiService.StartupParameters.Split(';')

    # Removing extra flags
    foreach ($parameter in $wmiService.StartupParameters.Split(';')) {
        if ($parameter -like '-T*' -and $parameter -notin $traceFlagList) {
            $parameterList.Remove($parameter) | Out-Null
        }
    }

    # Add missing flags
    foreach ($Flag in $traceFlagList) {
        if ($Flag -notin $parameterList) {
            $parameterList.Add($Flag) | Out-Null
        }
    }

    # Merge flags back into startup parameters
    $wmiService.StartupParameters = $parameterList -join ';'
    $wmiService.Alter()

    if ($RestartSQLService)
    {
        $wmiService.Stop()
        Start-Sleep -Seconds 10
        $wmiService.Start()

        ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq 'SQLSERVERAGENT' }).Start()
    }
}

function Remove-SQLTraceFlag
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Position = 1)]
        [System.String]
        $SQLInstanceName = 'MSSQLServer',

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [System.String[]]
        $TraceFlag,

        [switch]
        $RestartSQLService
    )

    Initialize-SQLSMOAssembly
    $sqlManagement = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $wmiService = $sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq $SQLInstanceName }

    # Add '-' dash to flag
    $traceFlagList = $TraceFlag | ForEach-Object {
        "-$PSItem"
    }

    # Extract flags from startup parameters
    [System.Collections.ArrayList]$parameterList = $wmiService.StartupParameters.Split(';')

    # Add missing flags
    foreach ($Flag in $traceFlagList) {
        if ($Flag -in $parameterList) {
            $parameterList.Remove($Flag) | Out-Null
        }
    }

    # Merge flags back into startup parameters
    $wmiService.StartupParameters = $parameterList -join ';'
    $wmiService.Alter()

    if ($RestartSQLService)
    {
        $wmiService.Stop()
        Start-Sleep -Seconds 10
        $wmiService.Start()

        ($sqlManagement.Services | Where-Object -FilterScript { $PSItem.Name -eq 'SQLSERVERAGENT' }).Start()
    }
}

function Initialize-SQLSMOAssembly {

    # Source: https://blog.netnerds.net/2016/12/loading-smo-in-your-sql-server-centric-powershell-modules/
    $smoversions = "14.0.0.0", "13.0.0.0", "12.0.0.0", "11.0.0.0", "10.0.0.0", "9.0.242.0", "9.0.0.0"

    foreach ($smoversion in $smoversions)
    {
        try
        {
            Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=$smoversion, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
            $smoadded = $true
        }
        catch
        {
            $smoadded = $false
        }
    
        if ($smoadded -eq $true) { break }
    }

    if ($smoadded -eq $false) { throw "Can't load SMO assemblies. You must have SQL Server Management Studio installed to proceed." }

    $assemblies = "Management.Common", "Dmf", "Instapi", "SqlWmiManagement", "ConnectionInfo", "SmoExtended", "SqlTDiagM", "Management.Utility",
    "SString", "Management.RegisteredServers", "Management.Sdk.Sfc", "SqlEnum", "RegSvrEnum", "WmiEnum", "ServiceBrokerEnum", "Management.XEvent",
    "ConnectionInfoExtended", "Management.Collector", "Management.CollectorEnum", "Management.Dac", "Management.DacEnum", "Management.IntegrationServices"

    foreach ($assembly in $assemblies)
    {
        try
        {
            Add-Type -AssemblyName "Microsoft.SqlServer.$assembly, Version=$smoversion, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
        }
        catch
        {
            # Don't care
        }
    }
}