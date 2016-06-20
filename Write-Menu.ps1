<#
    Write-Menu: Outputs a command-line menu which can be navigated using the keyboard.
    Copyright (C) 2016 QuietusPlus

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

function Write-Menu {
    <#
        .NOTES
            Write-Menu
            by QuietusPlus

            Based on "Simple Textbased Powershell Menu" by Michael Albert [info@michlstechblog.info]

        .SYNOPSIS
            Outputs a command-line menu, which can be navigated using the keyboard.

        .DESCRIPTION
            Outputs a command-line menu, which can be navigated using the keyboard.

            Controls             Description
            --------             -----------
            Arrow Up + Down      Change selection
            Arrow Left + Right   Switch pages
            Enter                Confirm selection
            Escape               Exit menu

        .PARAMETER Items
            Menu entries.

        .PARAMETER Title
            Title shown at the top.

        .PARAMETER Page
            Page to display.

        .PARAMETER Sort
            Sort entries before they are added to the menu.

        .EXAMPLE
            PS > $menuReturn = Write-Menu -Title 'Menu Title' -Entries @('Menu Option 1', 'Menu Option 2', 'Menu Option 3', 'Menu Option 4')

             Menu Title

              Menu Option 1
              Menu Option 2
              Menu Option 3
              Menu Option 4

             Page 1 / 1

        .EXAMPLE
            PS > $menuReturn = Write-Menu -Title 'AppxPackages' -Entries (Get-AppxPackage).Name -Sort

            This example uses Write-Menu to sort and list app packages (Windows Store/Modern Apps) that are installed for the current profile.

        .LINK
            https://github.com/QuietusPlus/Write-Menu
    #>

    [CmdletBinding()]

    <#
        Parameters
    #>

    param (
        [Parameter(ValueFromPipeline = $true)]
        [Alias('Items')]
        $Entries,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        $Title,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Int16]$Page,

        [Parameter()]
        [switch]$Sort
    )

    # Clear screen
    Clear-Host

    <#
        Checks
    #>

    # Parameter: Entries
    if ($Entries -like $null) { Write-Error "Missing -Entries parameter!"; return }
    # Parameter: Page
    if ($Page -like $null) { $Page = 0 }
    # Parameter: Title
    if ($Title -notlike $null) {
        [System.Console]::WriteLine("`n " + $Title + "`n") # Display title
        $pageListSize = ($host.UI.RawUI.WindowSize.Height - 7) # Set menu height
    } else {
        [System.Console]::WriteLine('') # Skip title display
        $pageListSize = ($host.UI.RawUI.WindowSize.Height - 5) # Set menu height
    }
    # Parameter: Sort
    if ($Sort -eq $true) { $Entries = $Entries | Sort-Object }
    # Make sure host is console window
    if ($host.Name -ne 'ConsoleHost') { Write-Error "[$($host.Name)] Cannot run inside host, please use a console window instead!"; return }

    <#
        Colours
    #>

    $colorForegroundSaved = [System.Console]::ForegroundColor; $colorBackgroundSaved = [System.Console]::BackgroundColor # Save original colours
    $colorForeground = $colorForegroundSaved; $colorBackground = $colorBackgroundSaved # Set colours, modify this to change colours
    $colorForegroundSelected = $colorBackground; $colorBackgroundSelected = $colorForeground # Set inverted colours

    <#
        Initialisation
    #>

    # Amount of entries in total
    $entriesTotal = $Entries.Length
    # First entry of page (location within entire array)
    $pageFirstEntry = ($pageListSize * $Page)
    # Total pages
    $pageTotal = [math]::Ceiling((($entriesTotal - $pageListSize) / $pageListSize))
    # Amount of entries on last page
    if ($Page -eq $pageTotal) { $pageEntriesCount = ($entriesTotal - ($pageListSize * $pageTotal))
    # Amount of entries on fully populated page
    } else { $pageEntriesCount = $pageListSize }

    # Position within console
    $positionCurrent = 0
    $positionSelected = 0
    $positionTotal = 0
    $positionTop = [System.Console]::CursorTop

    # Get entries for current page
    $pageEntries = @()
    foreach ($i in 0..$pageListSize) {
        $pageEntries += $Entries[($pageFirstEntry + $i)]
    }

    <#
        Write Page
    #>

    do {
        $menuLoop = $true
        [System.Console]::CursorTop = ($positionTop - $positionTotal)
        for ($positionCurrent = 0; $positionCurrent -le ($pageEntriesCount - 1); $positionCurrent++) {
            # Replace previous line
            [System.Console]::Write("`r")
            # If selected, invert colours
            if ($positionCurrent -eq $positionSelected) { [System.Console]::BackgroundColor = $colorBackgroundSelected; [System.Console]::ForegroundColor = $colorForegroundSelected }
            # Write entry
            [System.Console]::Write('  ' + $pageEntries[$positionCurrent] + '  ')
            # Reset colours
            [System.Console]::BackgroundColor = $colorBackground; [System.Console]::ForegroundColor = $colorForeground
            # Empty line
            [System.Console]::WriteLine('')
        }

        # Write page indicator
        [System.Console]::WriteLine("`n Page $($Page + 1) / $($pageTotal + 1)`n")

        <#
            User Input
        #>

        # Read key input
        $menuInput = [System.Console]::ReadKey($true)

        switch ($menuInput.Key) {
            'DownArrow' {
                # Check: End of list
                if ($positionSelected -lt ($pageEntriesCount - 1)) { $positionSelected++ } }
            'UpArrow' {
                # Check: Top of list
                if ($positionSelected -gt 0) { $positionSelected-- } }
            'Enter' {
                # Return: Selected entry
                $menuLoop = $false; Clear-Host; return ($pageEntries[$positionSelected]) }
            'Escape' {
                # Return: $false
                $menuLoop = $false; Clear-Host; return $false }
            'LeftArrow' {
                # Check: First page
                if ($Page -ne 0) { $menuLoop = $false; $Page--; Write-Menu -Entries $Entries -Page $Page -Title $Title } }
            'RightArrow' {
                # Check: Last page
                if ($Page -ne $pageTotal) { $menuLoop = $false; $Page++; Write-Menu -Entries $Entries -Page $Page -Title $Title } }
        }
    } while ($menuLoop)
}
