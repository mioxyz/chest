# Copyright Notice
Chest is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

# What is Chest?
It is a simple wrapper-tool and application launcher which encrypts
and decrypts files.

```
Synopsis:
Wrapper for file decryption, launch of an application to view or process said file and subsequent re-encryption. This script will make a temporary copy of a specified file, open it in some other application and encrypt and overwrite the original file, if changes have been made. The temporary files are then shredded and deleted. All of this is done as sudo, though the permissions of the encrypted file will belong to the normal user. Warning: Do not use this script in paralell, also not for different files. Very high risk of dataloss, due to the files almost certainly overwriting each other.

Usage:
chest [ COMMAND ] { APP | VOID } FILE_NAME
where COMMAND := { edit | use | create | encrypt }

Example:
chest use kak ligma.bls

Commands:
»edit«:     Allows you to edit an encrypted file with kak =: $EDITOR. example: »chest edit my_stuff.txt«
»use«:      Opens an encrypted file in the application of your choosing. example: »chest use kak asd.txt«
»create«:   Creates an empty file and opens it
»encrypt«:  Encrypts a specified file.
```

# Warning
These scripts haven't been tested extensively, and even though I 
do use the scripts to encrypt my diary, I wouldn't use it for things
which have significant value to others besides yourself. The files
you encrypt/descript and edit with chest might be overwritten or
irrepairably mangled if there are things I've not thought of in the script.
Hacking this software to your needs would be 

# How to install
1. save the script `chest_su.fish` as 'chest' as the super user.
2. save the script `chest.fish` as 'chest' as your normal user.

The point of the two scripts is to remove the requirement of having to 
type out `sudo chest USER_NAME ARGS...` and to get the user's username
such that root can later on set the permissions of the encrypted file 
to that of the user.

No idea if splitting the script up like this is how this is normally 
handled or not.

