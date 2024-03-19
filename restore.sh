 #!/run/current-system/sw/bin/bash

      # Initialize flags
      flag_n=false
      flag_h=false
      flag_v=false

      # Function to display usage information
      usage() {
        echo -e "Usage: $0 [-n] [-h] [-v] [-a]" >&2
        echo -e "  -n    restore nixos configuration \e[31m[REQUIRES SUDO]\e[0m"
        echo    "  -h    restore /home"
        echo -e "  -v    restore vm images (libvirtd) \e[31m[REQUIRES SUDO]\e[0m"
        echo -e "  -a    Activate all flags \e[31m[REQUIRES SUDO]\e[0m"
        exit 1
      }

      # Check if no options provided
      if [ $# -eq 0 ]; then
        usage
      fi
    
      findHomeDir() {
        home_check=(/home/*/)
      
        # Check if there's only one user directory
        if [ ${#home_check[@]} -eq 1 ]; then
          homeDir="${home_check[0]%/}"
          echo -e "Will back up \e[32m$homeDir\e[0m"
        else
          # If there are multiple directories, prompt the user to select a homeDir
          echo "Multiple user directories found in /home:"
          select homeDir in "${home_check[@]}"; do
            if [ -n "$homeDir" ]; then
              homeDir="${homeDir%/}"
              echo -e "Will restore to \e[32m$homeDir\e[0m"
              break
            else
              echo -e "\e[31mInvalid selection. Please choose a number from the list.\e[0m"
            fi
          done
        fi
      }

      # Check if backup disk exists
      disk=$(df -h | awk '/\/run\/media\// {print $NF}')
      if [ ! -d "$disk" ]; then
        echo -e "Default backup disk $disk not found. (usually at \e[32m[/run/media/<user>/<disk>\e[0m)"
        read -p "   Please enter another path to backup: " disk
      fi
      while true; do 
        echo -e "   Is \e[32m$disk\e[0m your backup location? (yes/no)"
        read -r confirmation
        case $confirmation in
          yes)
            break
            ;;
          no)
            while true; do
              read -p "   Please enter another path to backup location: " disk
              if [ -d "$disk" ]; then
                break
              else
                echo -e "\e[31mERROR:\e[0m Directory \e[32m$disk\e[0m does not exist"
              fi
            done
            ;;
          *)
            echo "ONLY yes or no"
            ;;
        esac
      done

      # Parse command line options
      while getopts ":nhva" option; do
        case $option in
          n)
            # Check if sudo is used
            if [ "$(id -u)" != "0" ]; then
              echo -e "\e[31mError: -n flag requires sudo.\e[0m"
              usage
            fi
            flag_n=true
            ;;
          h)
            findHomeDir
            flag_h=true
            ;;
          v)
            # Check if sudo is used
            if [ "$(id -u)" != "0" ]; then
                echo -e "\e[31mError: -v flag requires sudo.\e[0m"
                usage
            fi
            flag_v=true
            ;;
          a)
            # Check if sudo is used
            if [ "$(id -u)" != "0" ]; then
                echo -e "\e[31mError: -a flag requires sudo.\e[0m"
                usage
            fi
            findHomeDir
            flag_n=true
            flag_h=true
            flag_v=true
            ;;
          *)
            usage
            ;;
        esac
      done

      # Output based on flags
      if $flag_n; then
        rsync -hiva --exclude='hardware-configuration.nix' "$disk"/Back_Up/nixos/ /etc/nixos/
      fi
      if $flag_h; then
        rsync -hiva "$disk"/Back_Up"$homeDir"/ "$homeDir"/
      fi
      if $flag_v; then
        rsync -hiva "$disk"/Back_Up/vm-backup/images/ /var/lib/libvirt/images/
      fi

      exit 0
