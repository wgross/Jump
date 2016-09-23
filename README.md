# Jump
Powershell directory shortcuts.

## Usage
This small module allows to manage a list of directory shortcuts. Invoking a shortcut changes the current location to the designated directory.
Shortcuts can also be listed or removed if they are no longer needed.

All Shortcuts are stored in a JSON file relatively to the Jump.psm1 in directory 'Jumps/&lt;machinename&gt;.json'. Invoking a jump always creates a new jump named 'back' pointing to the source of the jump. This makes it easy to switch between two directories quickly. The back-jump hasn't to be called explicitely: just call 'Invoke-Jump' without jump name to move back.

## Installation
The module is currently not avalaible on the poesrhell gallery. Just clone the repository to an place in your module path and you should be ready to go.

I'm using it as a git submodule of in my profile repository which works quite well. For developement I'm keeping another clone outside of my module path to make sure the Pester-tests don't mess up my list of Jumps. 
