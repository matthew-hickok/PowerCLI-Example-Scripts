﻿function Get-VMCPSettings {
<#	
	.NOTES
	===========================================================================
	 Created on:   	10/27/2015 9:25 PM
	 Created by:   	Brian Graf
     Twitter:       @vBrianGraf
     VMware Blog:   blogs.vmware.com/powercli
     Personal Blog: www.vtagion.com

     Modified on:  	10/11/2016
	 Modified by:  	Erwan Quélin
     Twitter:       @erwanquelin
     Github:        https://github.com/equelin    
	===========================================================================
	.DESCRIPTION
    This function will allow users to view the VMCP settings for their clusters

    .PARAMETER Cluster
    Cluster Name or Object

    .PARAMETER Server
    vCenter server object

    .EXAMPLE
    Get-VMCPSettings

    This will show you the VMCP settings for all the clusters

    .EXAMPLE
    Get-VMCPSettings -cluster LAB-CL

    This will show you the VMCP settings of your cluster

    .EXAMPLE
    Get-VMCPSettings -cluster (Get-Cluster Lab-CL)

    This will show you the VMCP settings of your cluster

    .EXAMPLE
    Get-Cluster | Get-VMCPSettings

    This will show you the VMCP settings for all the clusters
#>
    [CmdletBinding()]
    param
    (
    [Parameter(Mandatory=$False,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage='What is the Cluster Name?')]
    $cluster = (Get-Cluster -Server $Server),

    [Parameter(Mandatory=$False)]
    [VMware.VimAutomation.Types.VIServer[]]$Server = $global:DefaultVIServers
    )

    Process {

        Foreach ($Clus in $Cluster) {

            Write-Verbose "Processing Cluster $($Clus.Name)"

            # Determine input and convert to ClusterImpl object
            Switch ($Clus.GetType().Name)
            {
                "string" {$CL = Get-Cluster $Clus  -Server $Server -ErrorAction SilentlyContinue}
                "ClusterImpl" {$CL = $Clus}
            }

            If ($CL) {
                # Work with the Cluster View
                $ClusterMod = Get-View -Id "ClusterComputeResource-$($CL.ExtensionData.MoRef.Value)" -Server $Server

                # Create Hashtable with desired properties to return
                $properties = [ordered]@{
                    'Cluster' = $ClusterMod.Name;
                    'VMCP Status' = $clustermod.Configuration.DasConfig.VmComponentProtecting;
                    'Protection For APD' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD;
                    'APD Timeout Enabled' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.EnableAPDTimeoutForHosts;
                    'APD Timeout (Seconds)' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec;
                    'Reaction on APD Cleared' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared;
                    'Protection For PDL' = $clustermod.Configuration.DasConfig.DefaultVmSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL
                }

                # Create PSObject with the Hashtable
                $object = New-Object -TypeName PSObject -Prop $properties

                # Show object
                $object
            }
        }
    }
}

function Set-VMCPSettings {
<#	
	.NOTES
	===========================================================================
	 Created on:   	10/27/2015 9:25 PM
	 Created by:   	Brian Graf
     Twitter:       @vBrianGraf
     VMware Blog:   blogs.vmware.com/powercli
     Personal Blog: www.vtagion.com

     Modified on:  	10/11/2016
	 Modified by:  	Erwan Quélin
     Twitter:       @erwanquelin
     Github:        https://github.com/equelin    
	===========================================================================
	.DESCRIPTION
    This function will allow users to enable/disable VMCP and also allow
    them to configure the additional VMCP settings
    For each parameter, users should use the 'Tab' button to auto-fill the
    possible values.

    .PARAMETER Cluster
    Cluster Name or Object

    .PARAMETER enableVMCP
    Enable or disable VMCP

    .PARAMETER VmStorageProtectionForPDL
    VM Storage Protection for PDL settings. Might be:
    - disabled
    - warning
    - restartAggressive

    .PARAMETER VmStorageProtectionForAPD
    VM Storage Protection for APD settings. Might be:
    - disabled
    - restartConservative
    - restartAggressive
    - warning

    .PARAMETER VmTerminateDelayForAPDSec
    VM Terminate Delay for APD (seconds).

    .PARAMETER VmReactionOnAPDCleared
    VM reaction on APD Cleared. Might be:
    - reset
    - none

    .PARAMETER Server
    vCenter server object

    .EXAMPLE
    Set-VMCPSettings -cluster LAB-CL -enableVMCP:$True -VmStorageProtectionForPDL `
    restartAggressive -VmStorageProtectionForAPD restartAggressive `
    -VmTerminateDelayForAPDSec 2000 -VmReactionOnAPDCleared reset 

    This will enable VMCP and configure the Settings on cluster LAB-CL

    .EXAMPLE
    Set-VMCPSettings -cluster LAB-CL -enableVMCP:$False -VmStorageProtectionForPDL `
    disabled -VmStorageProtectionForAPD disabled `
    -VmTerminateDelayForAPDSec 600 -VmReactionOnAPDCleared none 

    This will disable VMCP and configure the Settings on cluster LAB-CL

    .EXAMPLE
    Set-VMCPSettings -enableVMCP:$False -VmStorageProtectionForPDL `
    disabled -VmStorageProtectionForAPD disabled `
    -VmTerminateDelayForAPDSec 600 -VmReactionOnAPDCleared none 

    This will disable VMCP and configure the Settings on all clusters available
#>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param
    (
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage='What is the Cluster Name?')]
        $cluster= (Get-Cluster -Server $Server),
        
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$False,
        HelpMessage='True=Enabled False=Disabled')]
        [switch]$enableVMCP,

        [Parameter(Mandatory=$True,
        ValueFromPipeline=$False,
        HelpMessage='Actions that can be taken in response to a PDL event')]
        [ValidateSet("disabled","warning","restartAggressive")]
        [string]$VmStorageProtectionForPDL,
        
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$False,
        HelpMessage='Options available for an APD response')]
        [ValidateSet("disabled","restartConservative","restartAggressive","warning")]
        [string]$VmStorageProtectionForAPD,
        
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$False,
        HelpMessage='Value in seconds')]
        [Int]$VmTerminateDelayForAPDSec,
        
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$False,
        HelpMessage='This setting will instruct vSphere HA to take a certain action if an APD event is cleared')]
        [ValidateSet("reset","none")]
        [string]$VmReactionOnAPDCleared,
        
        [Parameter(Mandatory=$False)]
        [VMware.VimAutomation.Types.VIServer[]]$Server = $global:DefaultVIServers
    )

    Process {

        Foreach ($Clus in $Cluster) {

            Write-Verbose "Processing Cluster $Clus"

            # Determine input and convert to ClusterImpl object
            Switch ($Clus.GetType().Name)
            {
                "string" {$CL = Get-Cluster $Clus -Server $Server -ErrorAction SilentlyContinue}
                "ClusterImpl" {$CL = $Clus}
            }

            If ($CL) {
                # Create the object we will configure
                $settings = New-Object VMware.Vim.ClusterConfigSpecEx
                $settings.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
                
                # Based on $enableVMCP switch 
                if ($enableVMCP -eq $false)  { 
                    $settings.dasConfig.vmComponentProtecting = "disabled"
                } 
                elseif ($enableVMCP -eq $true) { 
                    $settings.dasConfig.vmComponentProtecting = "enabled" 
                }  

                #Create the VMCP object to work with
                $settings.dasConfig.defaultVmSettings = New-Object VMware.Vim.ClusterDasVmSettings
                $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings = New-Object VMware.Vim.ClusterVmComponentProtectionSettings

                #Storage Protection For PDL
                $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForPDL = "$VmStorageProtectionForPDL"

                #Storage Protection for APD
                switch ($VmStorageProtectionForAPD) {
                    "disabled" {
                        # If Disabled, there is no need to set the Timeout Value
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'disabled'
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $false
                    }

                    "restartConservative" {
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'restartConservative'
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $true
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = $VmTerminateDelayForAPDSec
                    }

                    "restartAggressive" {
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'restartAggressive'
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $true
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = $VmTerminateDelayForAPDSec
                    }

                    "warning" {
                        # If Warning, there is no need to set the Timeout Value
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'warning'
                        $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.enableAPDTimeoutForHosts = $false
                    }

                }

                # Reaction On APD Cleared
                $settings.dasConfig.defaultVmSettings.vmComponentProtectionSettings.vmReactionOnAPDCleared = "$VmReactionOnAPDCleared"

                # Execute API Call
                $modify = $true
                $ClusterMod = Get-View -Id "ClusterComputeResource-$($CL.ExtensionData.MoRef.Value)" -Server $Server

                If ($pscmdlet.ShouldProcess($CL.Name,"Modify VMCP configuration")) {
                    $ClusterMod.ReconfigureComputeResource_Task($settings, $modify) | out-null
                }

                # Show result
                Get-VMCPSettings -Cluster $CL -Server $Server
            }
        }
    }
}
