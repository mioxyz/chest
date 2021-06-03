function chest
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
         if not test -f $argv[3]
            echo "File doesn't exist."
         else
            set location (string split "/" -- $argv[3])
            if test "$location[1]" = "dev"; or test "$location[2]" = "dev"
               echo "This script probably shouldn't be called on files in »/dev/*«."
            end
            read pass --local --silent --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
            # the »2>&1« thing at the end adds stderr to stdout
            set openssl_stderr (openssl aes-256-cbc -d -a -iter 5 -pass "pass:$pass" -in $argv[3] -out $temp_txt 2>&1)
            if test -n "$openssl_stderr"
               echo "Encountered error during document decryption. Aborting."
               echo "---"
               echo "$openssl_stderr"
               echo "---"
            else
               set hash_before (sha256sum $temp_txt)
               set hash_before (string split " " -- $hash_before)[1]
               nano $temp_txt
               set hash_after (sha256sum $temp_txt)
               set hash_after (string split " " -- $hash_after)[1]
               # echo "hash_before: $hash_before"
               # echo "hash_after:  $hash_after"
               if test "$hash_before" = "$hash_after"
                  echo "files haven't changed, not saving to file."
               else
                  echo "file has changed, encrypting file..."
                  set openssl_encrypt_stderr (openssl aes-256-cbc -salt -e -a -iter 5 -pass "pass:$pass" -in "$temp_txt" -out "$temp_enc")
                  if test -n "$openssl_encrypt_stderr"
                     echo "Encountered error during encryption. Files in »$temp_dir« are not being shredded! Manually do this."
                  else
                     # copy operation also can fail.
                     cp $temp_enc $argv[3]
                     shred -n 3 $temp_txt $temp_enc
                     chmod go+r $argv[3]
                     chown $mesa_user $argv[3]
                     chgrp $mesa_user $argv[3]
                  end # <~ openssl err
               end # <~ file hash comparison
            end # <~ openessl stderr
         end # <~ file doesn't exist
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
      case use
         set application $argv[3]
         set real_enc $argv[4]
         if not test -f $real_enc
            echo "File doesn't exist."
         else
            read pass --local --silent --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
            set openssl_stderr (openssl aes-256-cbc -d -a -iter 5 -pass "pass:$pass" -in $real_enc -out $temp_txt 2>&1)
            if test -n "$openssl_stderr"
               echo Encountered error during document decryption. Aborting.\n---
               echo "$openssl_stderr"
               echo ---
            else
               set hash_before (string split " " -- (sha256sum $temp_txt))[1]
               $application $temp_txt
               set hash_after (string split " " -- (sha256sum $temp_txt))[1]
               if not test "$hash_before" = "$hash_after"
                  echo "file has changed, encrypting file..."
                  set openssl_encrypt_stderr (openssl aes-256-cbc -salt -e -a -iter 5 -pass "pass:$pass" -in "$temp_txt" -out "$temp_enc")
                  if test -n "$openssl_encrypt_stderr"
                     echo "Encountered error during encryption. Files in »$temp_dir« are not being shredded! Manually do this."
                  else
                     # copy operation also can fail.
                     cp $temp_enc $real_enc
                     shred -n 3 $temp_txt $temp_enc
                     chmod go+r $real_enc
                     chown $mesa_user $real_enc
                     chgrp $mesa_user $real_enc
                  end # <~ openssl err
               end # <~ file hash comparison
            end # <~ openessl stderr
         end # <~ file doesn't exist
      case encrypt #simply encrypt an existing file, do not edit
         set real_txt $argv[4]
         set real_enc $real_txt.enc
         if not test -f $real_txt
            echo "File doesn't exist."
         else
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
               end # <~ openssl err
            end # <~ encrypted file exists
         end # <~ file exists
      case '*'
         echo "unknown verb: $argv[2]"
   end # <~ switch verb
end
