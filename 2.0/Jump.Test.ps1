Import-Module Pester
Import-Module $PSScriptRoot\Jump.psm1 -Force -Prefix sut

Describe "Set-Jump cmdlet" {
    
    BeforeEach {
        Clear-sutJumps
    }
    
    It "Set-Jump -Name writes an updated jump file to the disk" {
        Set-sutJump -Name "test" -Destination "c:\test"           

        Test-Path $PSScriptRoot/Jumps/$env:ComputerName.json | Should Be $true
        
        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.test | Should Be "c:\test"
    }

    It "Set-Jump without a name takes the base name of the destination" {
        Set-sutJump -Destination "c:\zumsel"           

        $content = Get-Content $PSScriptRoot/Jumps/$env:ComputerName.json | ConvertFrom-Json
        $content.zumsel | Should Be "c:\zumsel"
    }

    It "Set-Jump without a destination take the base name of the current working directory" {
        try {
            mkdir TestDrive:\nodestination
            Set-Location TestDrive:\noDestination
            Set-sutJump
            (Get-sutJump noDestination).Destination | Should Be "TestDrive:\noDestination"
        } finally {
            Set-Location $PSScriptRoot
        }
    }
}

Describe "Get-Jump cmdlet" {
    
    BeforeEach {
        Clear-sutJumps
        Set-sutJump -Destination "c:\zumsel"           
    }

    It "Get-jump returns a directory by its name" {
        
        (Get-sutJump zumsel).Destination | Should Be "c:\zumsel"
    }

    It "Get-jump returns a list of known jump destinations" {
        $list = Get-sutJump
        $list.Length  | Should Be 1
        $list[0].Name | Should Be "zumsel"
        $list[0].Destination | Should Be "c:\zumsel"
    }
}

Describe "Remove-Jump cmdlet" {

    BeforeEach {
        Clear-sutJumps
        Set-sutJump -Destination "c:\zumsel"           
    }

    It "Remove-jump deletes an alias and its destination from the repository" {
        Remove-sutJump "zumsel"
        Get-sutJump zumsel | Should Be $null
    }
}

Describe "Invoke-Jump cmdlet" {

    BeforeEach {
        Clear-sutJumps
        mkdir TestDrive:\dest -ErrorAction SilentlyContinue
        Set-sutJump -Destination "TestDrive:\dest"           
    }

    It "Invoke-Jump changes the location to the destination of the named jump" {
        Push-Location
        Invoke-sutJump dest
        (Get-Location).Path | Should Be TestDrive:\dest
        Pop-Location
    }

    It "Invoke-Jump adds a 'back' jump destination with the PWD before jump" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Invoke-sutJump dest
            Invoke-sutJump back
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }

    It "Invoke-Jump always jumps back if now name was given" {
        $currentLocation = Get-Item $PWD
        Push-Location
        try {
            Invoke-sutJump dest
            Invoke-sutJump
            Get-Location | Should Be $currentLocation.FullName
        } finally {
            Pop-Location
        }
    }
}

Describe "Import-V1Jump cmdlet" {
    BeforeAll {
        mkdir TestDrive:\Jumps|Out-Null
        "c:\testImport"|Out-File TestDrive:\Jumps\aJump
    }

    It "Creates a new jump in V2 data from V1 jump definition" {
        Import-sutV1Jump -Directory TestDrive:\Jumps
        (Get-sutJump aJump).Destination | Should Be "c:\testImport"
    }
}