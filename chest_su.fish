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
   function lambda_edit # lambda_edit := mesa_user:str -> real_enc:str -> application:str => void
      set mesa_user $argv[1]
      set temp_dir $argv[2] # temporary working directory
      set temp_txt $argv[3] # temporary clear text file 
      set temp_enc $argv[4]  # temporary encrypted file
      set real_enc $argv[5] # real encoded file
      set application $argv[6] # target application
      if not test -f $real_enc
         echo "File »$real_enc« doesn't exist."
      else
         read pass --local --silent --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
         # the »2>&1« thing at the end adds stderr to stdout
         set openssl_stderr (openssl aes-256-cbc -d -a -iter 5 -pass "pass:$pass" -in $real_enc -out $temp_txt 2>&1)
         if test -n "$openssl_stderr"
            echo Encountered error during document decryption. Aborting.\n---
            echo "$openssl_stderr"
         else
            set hash_before (string split " " -- (sha256sum $temp_txt))[1]         
            $application $temp_txt
            set hash_after (string split " " -- (sha256sum $temp_txt))[1]
            if test "$hash_before" = "$hash_after"
               echo "files haven't changed, not saving to file."
            else
               echo "file has changed, encrypting file..."
               set openssl_encrypt_stderr (openssl aes-256-cbc -salt -e -a -iter 5 -pass "pass:$pass" -in "$temp_txt" -out "$temp_enc")
               if test -n "$openssl_encrypt_stderr"
                  echo "Encountered error during encryption. Files in »$temp_dir« are not being shredded! Manually do this."
               else
                  # TODO copy operation also can fail.
                  cp $temp_enc $real_enc
                  shred -n 3 $temp_txt $temp_enc
                  chmod go+r $real_enc
                  chown $mesa_user $real_enc
                  chgrp $mesa_user $real_enc
               end # <~ openssl err
            end # <~ file hash comparison
         end # <~ openessl stderr
      end # <~ file doesn't exist
   end # <~ function
   echo "executing chest version A.3   @/root/.config/fish/functions/chest.fish"
   set temp_dir /tmp/chest # temporary working directory
   set temp_txt $temp_dir/edit.txt # temporary clear text file 
   set temp_enc $temp_dir/edit.enc # temporary encrypted file
   set mesa_user $argv[1] # unprivileged user calling chest via wrapper script of same name
   echo "mesa user: $mesa_user"
   mkdir -p $temp_dir
   touch $temp_txt $temp_enc
   chmod go-rwx $temp_txt $temp_enc
   switch $argv[2]
      case edit
         lambda_edit $mesa_user $temp_dir $temp_txt $temp_enc $argv[3] $EDITOR
      case use 
         lambda_edit $mesa_user $temp_dir $temp_txt $temp_enc $argv[4] $argv[3]
      case create
         set filename  "uninitialized"
         if test -n "$argv[3]" #; and test (string length $argv[3]) -eq 0
            echo "filename set in arguments. Filename is: »$argv[3]«."
            set filename $argv[3]
         else
            read filename --prompt="set_color brgreen; echo -n 'filename> '; set_color normal"
         end
         read pass --local --silent --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
         # get filename without extension, if *.enc extension is last in filename
         set split_filename (string split "." $filename)
         if test (count $split_filename) -gt 0; and test $split_filename[( count $split_filename )] = "enc"
           set filename (string sub --start 1 --length (math (string length $filename) - 4) $filename)
         end
         echo "fileName:$filename"
         set real_enc (pwd)/$filename.enc # real encoded file which will be copied to after editing the document.
         echo "real_enc:"
         echo »$real_enc«
         if test -f "$real_enc"
            echo "File exists already."
         else
            touch $temp_txt $real_enc
            chmod go-rwx $temp_txt $real_enc
            echo "" > $temp_txt
            nano $temp_txt
            set openssl_encrypt_stderr ( openssl aes-256-cbc -salt -e -a -iter 5 -pass "pass:$pass" -in "$temp_txt" -out "$temp_enc" )
            if test -n "$openssl_encrypt_stderr"
               echo "Encryption failed. Please manually delete temporary files in »/tmp/chest/*« folder."
            else
               echo "Copying encoded file to abs fp: $real_enc"
               cp /tmp/chest/edit.enc $real_enc
               shred -n 3 $temp_txt $temp_enc
               chmod go+r $real_enc
               chown $mesa_user $real_enc
               chgrp $mesa_user $real_enc
            end # <~ openssl err
         end # <~ file exists
      
      case encrypt #simply encrypt an existing file, do not edit
         set real_txt $argv[3]
         set real_enc $real_txt.enc
         if not test -f $real_txt
            echo "File doesn't exist."
         else
            echo real text: $real_txt
            if test -f $real_enc
               echo "An encrypted file »$real_enc« already exists in this directory!"
            else
               echo "Enter a password for the file which you wish to encrypt." 
               read pass --local --silent --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
               set openssl_stderr (openssl aes-256-cbc -d -a -iter 5 -pass "pass:$pass" -in $argv[3] -out $real_enc 2>&1)
               if test -n "$openssl_stderr"
                  echo Encountered error during document decryption. Aborting\n---
                  echo "$openssl_stderr"
                  echo ---
               else
                  echo "created encrypted file"
                  chmod go+r $real_enc
                  chown $mesa_user $real_enc
                  chgrp $mesa_user $real_enc
               end # <~ openssl err
            end # <~ encrypted file exists
         end # <~ file exists
      case '*'
         echo "unknown verb: $argv[2]"
   end # <~ switch verb
end
Editor exited but the function was not modified
