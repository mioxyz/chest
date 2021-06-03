# Defined in /tmp/fish.NEJNhA/chest.fish @ line 2
function chest
   switch $argv[1]
      case edit
         if not test -f $argv[2]
            echo "File doesn't exist."
         else
            set location (string split "/" -- $location)
            if test "$location[1]" = "dev"; or test "$location[2]" = "dev"
               echo "Encryption script shouldn't be called on »/dev/*« files. You risk formatting your harddrive."
            end
                  read --local --silent pass --prompt="set_color brgreen; echo -n 'pass> '; set_color normal"
            mkdir -p /tmp/chest
            touch /tmp/chest/edit.txt /tmp/chest/edit.enc
            chmod go-rwx /tmp/chest/edit.txt
            chmod go-rwx /tmp/chest/edit.enc
            # the »2>&1« thing at the end adds stderr to stdout
            set openssl_stderr (openssl aes-256-cbc -d -a -iter 5 -pass "pass:$pass" -in $argv[2] -out /tmp/chest/edit.txt 2>&1)
            if test -n "$openssl_stderr"
               echo "Encountered error during document decryption. Aborting."
            else
               set hash_before (sha256sum /tmp/chest/edit.txt)
               set hash_before (string split " " -- $hash_before)[1]
               nano /tmp/chest/edit.txt
               set hash_after (sha256sum /tmp/chest/edit.txt)
               set hash_after (string split " " -- $hash_after)[1]
               echo "hash_before: $hash_before"
               echo "hash_after:  $hash_after"
               if test "$hash_before" = "$hash_after"
                  echo "hashes are equal, not saving to file."
               else
                  echo "file has changed, encrypting file..."
                  set openssl_encrypt_stderr (openssl aes-256-cbc -salt -e -a -iter 5 -pass "pass:$pass" -in "/tmp/chest/edit.txt" -out /tmp/chest/edit.enc)
                  if test -n "$openssl_encrypt_stderr"
                     echo "Encountered error during encryption. Files in »/tmp/chest/« are not being shredded! Manually do this."
                  else
                     # copy operation also can fail.
                     cp /tmp/chest/edit.enc $argv[2]
                     shred -n 3 /tmp/chest/edit.txt /tmp/chest/edit.enc
                  end
               end
            end # <~ openessl stderr
         end # <~ file doesn't exist
      case use
         echo "TODO"
      case '*'
        echo "unknown verb: $argv[1]"
      case create
   end
end
