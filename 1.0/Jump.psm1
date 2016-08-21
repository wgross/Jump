write-Host "Loading module Jump..."

Set-Variable -Name "JumpRepositoryPath" -Value "$PSScriptRoot\jumps\$env:COMPUTERNAME" `
    -Description "Directory to store the 'jump'-modules jump defintion files in" `
    -Option AllScope,Constant `
    -Scope Global `
    -ErrorAction SilentlyContinue

    
if(!(Test-Path $JumpRepositoryPath)) {
	mkdir $JumpRepositoryPath
}

function Import-JumpRepository {
    param(
        $From
    )
    process {
        $jumpRepository = @{}
        Get-ChildItem $JumpRepositoryPath | foreach {
            $jumpDestination = (Get-Content (Join-Path  $JumpRepositoryPath $_.Name))
            New-Object PSCustomObject -Property @{
                Name = $_.Name
                Destination = $jumpDestination
            }
        } | foreach {
            $jumpRepository.Item($_.Name) = $_.Destination
        }
        return $jumpRepository
    }
}

Set-Variable -Name "JumpRepository" -Value $(Import-JumpRepository) `
    -Description "File to store the 'jump' adresses in" `
    -Option AllScope,Constant `
    -Scope Global `
    -ErrorAction SilentlyContinue

#region Set, get and invoke jumps

function Set-Jump {
    <#
    .SYNOPSIS
	    Creates or changes a jump alias for the specified directory.
    .DESCRIPTION
	    Creates or changes a jump alias for the specified directory.
	    Aliases are stored in the modules directory in subdirectory jump\$Env:COMPUTERNAME
	    if no name is specified the default name 'last' is used.
    .PARAMETER Name
        Name of the created or changed jump destination
    .PARAMETER Destination
        path to the jump destination, may be an absolute path or a relative path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name = ($PWD|Get-Item).BaseName,
        [Parameter(Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        $Destination = (Get-Location).Path
    )
    process {
	    $Destination | Out-File $JumpRepositoryPath\$Name
        Write-Verbose "Set-Jump: $Name -> $Destination"
    }
}

function Get-Jump {
    <#
    .SYNOPSIS
	    Get specified jump adresses stored in $HOME\.jmp or list all jmp adresses.
    .DESCRIPTION
	    Get specified jump adresses stored in $HOME\.jmp or list all jmp adresses.
    .PARAMETER Name
        Name of the created or changed jump destination
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$false)]
        [string]$Name
    )
    process
    {
        function listAllJumps {
            Get-ChildItem $JumpRepositoryPath | ForEach-Object {
                
                $comment = ""
                $jumpDestination = (Get-Content (Join-Path  $JumpRepositoryPath $_.Name))

                # too slow
                #if(!(Test-Path $jumpDestination)) { $comment += "?" }
                
                if($jumpDestination -eq $PWD.Path) { $comment +="<-PWD" }

                New-Object PSCustomObject -Property @{
                    Name = $_.Name
                    Destination = $jumpDestination
                    Comment = $comment
                }

            } | Format-Table -Property Name,Destination,Comment -AutoSize
        }

        if([System.String]::IsNullOrEmpty($Name)) {
            # No jump name given. Just show all available jumps
            listAllJumps
        } else {
        
            $jumps = @()

            # try to jump to configured destination

            if(Test-Path (Join-Path $JumpRepositoryPath $name)) {
                # return the conntet of an existing jump destination file
                $jumps += (Get-Item (Join-Path $JumpRepositoryPath $name) | ForEach-Object {
                    New-Object PSCustomObject -Property @{
                        Name = $_.Name
                        Destination = (Get-Content (Join-Path  $JumpRepositoryPath $name) -TotalCount 1)
                    }
                })
            } 
            
            # try to jump to a parent directory

            $pathToRoot = $PWD.Path.ToLowerInvariant() -split "\\"

            if($pathToRoot.IndexOf($Name.ToLowerInvariant()) -gt -1) { 
                $jumps+= (New-Object PSCustomObject -Property @{
                    Name = $Name
                    Destination = ([System.String]::Join("\",($pathToRoot | Select-Object -First (($pathToRoot.IndexOf($Name.ToLowerInvariant())+1)))))  
               })
            }
            
            $jumps 
        }
    }
}

function Invoke-Jump {
    <#
    .SYNOPSIS
	    Jumps to the specifed location.
    .DESCRIPTION
        Destination 'back' allows to jump to the position before the last jump
        Destination 'last' repeats the last jump
        If no explicit jump alias is found, the directories names up to the file system root are compared to the jump destination
    .PARAMETER name
        Name of the jump destination. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$false)]
        #[ValidateScript({Test-Path (join-path  $JumpRepositoryPath $_)})]
        [string]$Name = "back"
    )
    process {
        $jump = (Get-Jump $Name | Select-Object -First 1)
            
        if(!($jump)) {
            # jump name wasn't found in parent directory path
            Write-Host "Couldn't resolve jump destination $Name" -ForegroundColor Red
        }

        # got a jump, but does it (still) exist?
        if(!(Test-path $jump.Destination)) {
            Write-Host -ForegroundColor Red "Destination $($jump.Destination) doesn't exist"
        } else {
            Write-Verbose "Jumping to labeled destination..."
            # Current location is new location for back jump
            Set-Jump -Name "back" -Destination $PWD.Path
            Write-Verbose "Back jump is now: $((Get-Jump -Name "back").Destination)"
            
            # Go to intended destination
            Set-Location $jump.Destination
            # Remember this jump as the 'last' jump destination
            Set-Jump -Name last -Destination $PWD.Path
        }
    }
} 

#endregion 

#region Utilities 

function Export-SpecialFoldersAsJump {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    process
    {
        [System.Enum]::GetNames([Environment+SpecialFolder]) | foreach {
            Set-Jump -Name $_ -Destination $([System.Environment]::GetFolderPath($_))
        }
    }
}

function Invoke-JumpToParent {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$ParentName
    )
    process {
        $start = (Get-Item $PWD).Parent
        while($start -ne $null) {
            if($start.BaseName.StartsWith($ParentName)) {
                # remober current path as back-jump
                Set-Jump -Name back
                # found parent with same name: go there
                Set-Location $start.FullName
                # remember jump target as last jump
                Set-Jump -Name las
                # stop searching 
                return
            } else {
                # test one level up
                $start = $start.Parent
            }
        }
        Write-Host "Could not find $ParentName in $PWD"
    } 
}      

#endregion 

#region Attach to Powershell 5 Tab Completion
#-Option ReadOnly,Constant `
    
New-Variable -Name "JumpRepositoryCompleter" -Description "Completer for invoke-Jump -Name values" `
    -Scope Global `
    -ErrorAction SilentlyContinue `
    -Value {
        param(
            $commandName, 
            $parameterName, 
            $wordToComplete, 
            $commandAst, 
            $fakeBoundParameter
        )

        Get-Jump "$wordToComplete*" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_.Name)
        }   
    }

Register-ArgumentCompleter -CommandName Invoke-Jump -ParameterName Name -ScriptBlock $global:JumpRepositoryCompleter
          
#endregion 
