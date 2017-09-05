# Load helper module
Import-Module -Name "$PSScriptRoot\cSQLServerTraceFlagHelper.psm1" -Verbose:$false -ErrorAction Stop

enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cSQLServerTraceFlag
{
    [DscProperty(Mandatory)]
    [Ensure]
    $Ensure

    [DscProperty(Key)]
    [System.String]
    $SQLInstanceName

    [DscProperty(Mandatory)]
    [System.String[]]
    $TraceFlag

    [DscProperty()]
    [System.Boolean]
    $RestartSQLService

    [void] Set()
    {
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # Create mandatory parameters
            $addSQLTraceFlagParameters = @{
                SQLInstanceName = $this.SQLInstanceName 
                TraceFlag = $this.TraceFlag 
                RestartSQLService = $this.RestartSQLService
            }
                
            Set-SQLTraceFlag @addSQLTraceFlagParameters
        }

        if ($this.Ensure -eq [Ensure]::Absent)
        {
            # Create mandatory parameters
            $addSQLTraceFlagParameters = @{
                SQLInstanceName = $this.SQLInstanceName 
                TraceFlag = $this.TraceFlag 
                RestartSQLService = $this.RestartSQLService
            }
                
            Remove-SQLTraceFlag @addSQLTraceFlagParameters
        }
    }        
    
    [bool] Test()
    {
        $currentStatus = $this.Get()

        $status = $true

        if ($this.Ensure -eq [Ensure]::Present)
        {           
            if ($currentStatus.Ensure -eq [Ensure]::Absent) 
            {
                Write-Verbose -Message ("'TraceFlag' does not match desired state. Current value: '{0}'. Desired Value: '{1}'." -f ($currentStatus.TraceFlag -join ','),($this.TraceFlag -join ','))
                $status = $false
            }
        }

        if ($this.Ensure -eq [Ensure]::Absent)
        {
            if ($currentStatus.Ensure -eq [Ensure]::Present)
            {
                # Retrieve desired flag list
                $desiredFlagList = [System.Collections.ArrayList]$currentStatus.TraceFlag
                $this.TraceFlag | Where-Object -FilterScript { $PSItem -in $this.TraceFlag } | ForEach-Object {
                    $desiredFlagList.Remove($PSItem)
                }

                Write-Verbose -Message ("'TraceFlag' does not match desired state. Current value: '{0}'. Desired Value: '{1}'." -f ($currentStatus.TraceFlag -join ','),($desiredFlagList -join ','))
                $status = $false
            }
        }

        return $status
    }    

    [cSQLServerTraceFlag] Get()
    {
        $status = [cSQLServerTraceFlag]::new()

        # Create mandatory parameters
        $getSQLTraceFlagParameters = @{
            SQLInstanceName = $this.SQLInstanceName 
        }

        $flagList = Get-SQLTraceFlag @getSQLTraceFlagParameters

        # Locate flags that should be in the flag list
        if ($this.Ensure -eq [Ensure]::Present)
        {
            $status.Ensure = [Ensure]::Present

            if ($null -ne $flagList)
            {
                if ($null -ne (Compare-Object -ReferenceObject $flagList -DifferenceObject $this.TraceFlag))
                {
                    $status.Ensure = [Ensure]::Absent
                }
            }
            else
            {
                $status.Ensure = [Ensure]::Absent
            }
        }

        # Locate flags that should not be in the flag list
        if ($this.Ensure -eq [Ensure]::Absent)
        {
            $status.Ensure = [Ensure]::Absent
            if ($null -ne $flagList)
            {
                foreach ($flag in $this.TraceFlag)
                {
                    if ($flag -in $flagList)
                    {
                        $status.Ensure = [Ensure]::Present
                    }
                }
            }            
        }

        $status.TraceFlag = $flagList

        return $status
    }    
}