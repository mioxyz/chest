# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

function chest
   echo "  _______"
   echo "  \\      \\"
   echo "  /______/"
   echo " /______/|  Chest A.3"
   echo " |``   | /"
   echo " \\_____l/"
   set mesa_user (whoami)
   if not contains -- $argv[1] [ "help" "--help" "-help" "h" ]
      sudo fish -c "chest $mesa_user $argv"
   else
      echo "";
      set_color --bold --underline; echo "Synopsis:";
      set_color normal;
      echo -n "Wrapper for file decryption, launch of an application to view or process said file and subsequent re-encryption. This script will make a temporary copy of a specified file, open it in some other application and encrypt and overwrite the original file, if changes have been made. The temporary files are then shredded and deleted. All of this is done as sudo, though the permissions of the encrypted file will belong to the normal user. ";
			set_color --bold --underline;
			echo -n "Warning:";
			set_color normal;
			echo " Do not use this script in paralell, also not for different files. Very high risk of dataloss, due to the files almost certainly overwriting each other."
      echo ""
      set_color --bold --underline; echo "Usage:";
      set_color normal;             echo -n "chest [ ";
      set_color --bold --underline; echo -n "COMMAND";
      set_color normal;             echo -n " ] { ";
      set_color --bold --underline; echo -n "APP";
      set_color normal;             echo -n " | ";
      set_color --bold --underline; echo -n "VOID";
      set_color normal;             echo -n " } ";
      set_color --bold --underline; echo "FILE_NAME";
      set_color normal;
      echo -n "where "
      set_color --bold --underline; echo -n "COMMAND";
      set_color normal;             echo -n " := { ";
      set_color --bold --underline; echo -n "edit";
      set_color normal;             echo -n " | ";
      set_color --bold --underline; echo -n "use"
      set_color normal;             echo -n " | ";
      set_color --bold --underline; echo -n "create"
      set_color normal;             echo -n " | ";
      set_color --bold --underline; echo -n "encrypt"
      set_color normal;             echo    " }";
      echo "";
      set_color --bold --underline; echo "Example:";
			set_color normal;
      echo "chest use kak ligma.bls";
      echo "";
      set_color --bold --underline; echo "Commands:"; set_color normal;   
      echo -n "»"; set_color brgreen; echo -n "edit"; set_color normal;
      echo "«:     Allows you to edit an encrypted file with $EDITOR =: \$EDITOR. example: »chest edit my_stuff.txt«";
      echo -n "»"; set_color brgreen; echo -n  "use"; set_color normal;
      echo "«:      Opens an encrypted file in the application of your choosing. example: »chest use kak asd.txt«";
      echo -n "»"; set_color brgreen; echo -n "create"; set_color normal;
      echo "«:   Creates an empty file and opens it ";
      echo -n "»"; set_color brgreen; echo -n "encrypt"; set_color normal;
      echo "«:  Encrypts a specified file."
   end
end
