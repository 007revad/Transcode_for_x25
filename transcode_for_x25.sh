#!/usr/bin/env bash
#----------------------------------------------------------------------------------
# https://www.blackvoid.club/unlocking-plex-hw-transcoding-on-x25-synology-models/
# https://www.blackvoid.club/content/files/2025/09/x25_hw_transcode_modules.zip
#----------------------------------------------------------------------------------

scriptver="v1.2.2"
script=Transcode_for_x25
repo="007revad/Transcode_for_x25"
scriptname=transcode_for_x25

# Shell Colors
#Black='\e[0;30m'   # ${Black}
#Red='\e[0;31m'     # ${Red}
#Green='\e[0;32m'   # ${Green}
#Yellow='\e[0;33m'   # ${Yellow}
#Blue='\e[0;34m'    # ${Blue}
#Purple='\e[0;35m'  # ${Purple}
Cyan='\e[0;36m'     # ${Cyan}
#White='\e[0;37m'   # ${White}
Error='\e[41m'      # ${Error}
Off='\e[0m'         # ${Off}

Cyan=""
Error=""
Off=""


ding(){ 
    printf \\a
}

if [[ $1 == "--trace" ]] || [[ $1 == "-t" ]]; then
    trace="yes"
fi

# Check script is running as root
if [[ $( whoami ) != "root" ]]; then
    ding
    echo -e "${Error}ERROR${Off} This script must be run as sudo or root!"
    exit 1  # Not running as sudo or root
fi

# Get NAS model
model=$(cat /proc/sys/kernel/syno_hw_version)
#modelname="$model"


# Show script version
#echo -e "$script $scriptver\ngithub.com/$repo\n"
echo "$script $scriptver"

# Get DSM full version
productversion=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION productversion)
buildphase=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildphase)
buildnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildnumber)
smallfixnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION smallfixnumber)

# Get CPU arch and platform_name
arch="$(uname -m)"
platform_name=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/synoinfo.conf platform_name)

# Show DSM full version and model
if [[ $buildphase == GM ]]; then buildphase=""; fi
if [[ $smallfixnumber -gt "0" ]]; then smallfix="-$smallfixnumber"; fi
echo "$model DSM $productversion-$buildnumber$smallfix $buildphase"

# Show CPU arch and platform_name
echo "CPU $platform_name $arch"


# Show options used
if [[ ${#args[@]} -gt "0" ]]; then
    echo -e "Using options: ${args[*]}\n"
else
    echo ""
fi


usage(){ 
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h, --help            Show this help message
  -v, --version         Show the script version
  -r, --restore         Restore default modules
      --autoupdate=AGE  Auto update script (useful when script is scheduled)
                          AGE is how many days old a release must be before
                          auto-updating. AGE must be a number: 0 or greater

EOF
    exit 0
}

scriptversion(){ 
    cat <<EOF
$script $scriptver - by 007revad

See https://github.com/$repo
EOF
    exit 0
}


# Save options used
args=("$@")


autoupdate=""

# Check for flags with getopt
if options="$(getopt -o abcdefghijklmnopqrstuvwxyz0123456789 -l \
    help,version,autoupdate:,restore,log,debug -- "$@")"; then
    eval set -- "$options"
    while true; do
        case "${1,,}" in
            -h|--help)          # Show usage options
                usage
                ;;
            -v|--version)       # Show script version
                scriptversion
                ;;
            -l|--log)           # Log (currently unused)
                log=yes
                ;;
            -d|--debug)         # Show and log debug info (currently unused)
                debug=yes
                ;;
            -r|--restore)       # Restore default modules
                restore=yes
                ;;
            --autoupdate)       # Auto update script
                autoupdate=yes
                if [[ $2 =~ ^[0-9]+$ ]]; then
                    delay="$2"
                    shift
                else
                    delay="0"
                fi
                ;;
            --)
                shift
                break
                ;;
            *)                  # Show usage options
                ding
                echo -e "Invalid option '$1'\n"
                usage
                exit 2  # Invalid argument
                ;;
        esac
        shift
    done
else
    echo
    usage
fi


#------------------------------------------------------------------------------
# Check latest release with GitHub API

syslog_set(){ 
    if [[ ${1,,} == "info" ]] || [[ ${1,,} == "warn" ]] || [[ ${1,,} == "err" ]]; then
        if [[ $autoupdate == "yes" ]]; then
            # Add entry to Synology system log
            /usr/syno/bin/synologset1 sys "$1" 0x11100000 "$2"
        fi
    fi
}


# Get latest release info
# Curl timeout options:
# https://unix.stackexchange.com/questions/94604/does-curl-have-a-timeout
release=$(curl --silent -m 10 --connect-timeout 5 \
    "https://api.github.com/repos/$repo/releases/latest")

# Release version
tag=$(echo "$release" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
shorttag="${tag:1}"

# Release published date
published=$(echo "$release" | grep '"published_at":' | sed -E 's/.*"([^"]+)".*/\1/')
published="${published:0:10}"
published=$(date -d "$published" '+%s')

# Today's date
now=$(date '+%s')

# Days since release published
age=$(((now - published)/(60*60*24)))


# Get script location
# https://stackoverflow.com/questions/59895/
source=${BASH_SOURCE[0]}
while [ -L "$source" ]; do # Resolve $source until the file is no longer a symlink
    scriptpath=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
    source=$(readlink "$source")
    # If $source was a relative symlink, we need to resolve it
    # relative to the path where the symlink file was located
    [[ $source != /* ]] && source=$scriptpath/$source
done
scriptpath=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
scriptfile=$( basename -- "$source" )
echo "Running from: ${scriptpath}/$scriptfile"

#echo "Script location: $scriptpath"  # debug
#echo "Source: $source"               # debug
#echo "Script filename: $scriptfile"  # debug

#echo "tag: $tag"              # debug
#echo "scriptver: $scriptver"  # debug


cleanup_tmp(){ 
    cleanup_err=

    # Delete downloaded .tar.gz file
    if [[ -f "/tmp/$script-$shorttag.tar.gz" ]]; then
        if ! rm "/tmp/$script-$shorttag.tar.gz"; then
            echo -e "${Error}ERROR${Off} Failed to delete"\
                "downloaded /tmp/$script-$shorttag.tar.gz!" >&2
            cleanup_err=1
        fi
    fi

    # Delete extracted tmp files
    if [[ -d "/tmp/$script-$shorttag" ]]; then
        if ! rm -r "/tmp/$script-$shorttag"; then
            echo -e "${Error}ERROR${Off} Failed to delete"\
                "downloaded /tmp/$script-$shorttag!" >&2
            cleanup_err=1
        fi
    fi

    # Add warning to DSM log
    if [[ $cleanup_err ]]; then
        syslog_set warn "$script update failed to delete tmp files"
    fi
}


if ! printf "%s\n%s\n" "$tag" "$scriptver" |
        sort --check=quiet --version-sort >/dev/null ; then
    echo -e "\n${Cyan}There is a newer version of this script available.${Off}"
    echo -e "Current version: ${scriptver}\nLatest version:  $tag"
    scriptdl="$scriptpath/$script-$shorttag"
    if [[ -f ${scriptdl}.tar.gz ]] || [[ -f ${scriptdl}.zip ]]; then
        # They have the latest version tar.gz downloaded but are using older version
        echo "You have the latest version downloaded but are using an older version"
        sleep 10
    elif [[ -d $scriptdl ]]; then
        # They have the latest version extracted but are using older version
        echo "You have the latest version extracted but are using an older version"
        sleep 10
    else
        if [[ $autoupdate == "yes" ]]; then
            if [[ $age -gt "$delay" ]] || [[ $age -eq "$delay" ]]; then
                echo "Downloading $tag"
                reply=y
            else
                echo "Skipping as $tag is less than $delay days old."
            fi
        else
            echo -e "${Cyan}Do you want to download $tag now?${Off} [y/n]"
            read -r -t 30 reply
        fi

        if [[ ${reply,,} == "y" ]]; then
            # Delete previously downloaded .tar.gz file and extracted tmp files
            cleanup_tmp

            if cd /tmp; then
                url="https://github.com/$repo/archive/refs/tags/$tag.tar.gz"
                if ! curl -JLO -m 30 --connect-timeout 5 "$url"; then
                    echo -e "${Error}ERROR${Off} Failed to download"\
                        "$script-$shorttag.tar.gz!"
                    syslog_set warn "$script $tag failed to download"
                else
                    if [[ -f /tmp/$script-$shorttag.tar.gz ]]; then
                        # Extract tar file to /tmp/<script-name>
                        if ! tar -xf "/tmp/$script-$shorttag.tar.gz" -C "/tmp"; then
                            echo -e "${Error}ERROR${Off} Failed to"\
                                "extract $script-$shorttag.tar.gz!"
                            syslog_set warn "$script failed to extract $script-$shorttag.tar.gz!"
                        else
                            # Set script sh files as executable
                            if ! chmod a+x "/tmp/$script-$shorttag/"*.sh ; then
                                permerr=1
                                echo -e "${Error}ERROR${Off} Failed to set executable permissions"
                                syslog_set warn "$script failed to set permissions on $tag"
                            fi

                            # Copy new script sh file to script location
                            if ! cp -p "/tmp/$script-$shorttag/${scriptname}.sh" "${scriptpath}/${scriptfile}";
                            then
                                copyerr=1
                                echo -e "${Error}ERROR${Off} Failed to copy"\
                                    "$script-$shorttag sh file(s) to:\n $scriptpath/${scriptfile}"
                                syslog_set warn "$script failed to copy $tag to script location"
                            fi

                            # Copy new CHANGES.txt file to script location (if script on a volume)
                            if [[ $scriptpath =~ /volume* ]]; then
                                # Set permissions on CHANGES.txt
                                if ! chmod 664 "/tmp/$script-$shorttag/CHANGES.txt"; then
                                    permerr=1
                                    echo -e "${Error}ERROR${Off} Failed to set permissions on:"
                                    echo "$scriptpath/CHANGES.txt"
                                fi

                                # Copy new CHANGES.txt file to script location
                                if ! cp -p "/tmp/$script-$shorttag/CHANGES.txt"\
                                    "${scriptpath}/${scriptname}_CHANGES.txt";
                                then
                                    if [[ $autoupdate != "yes" ]]; then copyerr=1; fi
                                    echo -e "${Error}ERROR${Off} Failed to copy"\
                                        "$script-$shorttag/CHANGES.txt to:\n $scriptpath"
                                else
                                    changestxt=" and changes.txt"
                                fi
                            fi

                            # Delete downloaded tmp files
                            cleanup_tmp

                            # Notify of success (if there were no errors)
                            if [[ $copyerr != 1 ]] && [[ $permerr != 1 ]]; then
                                echo -e "\n$tag ${scriptfile}$changestxt downloaded to: ${scriptpath}\n"
                                syslog_set info "$script successfully updated to $tag"

                                # Reload script
                                printf -- '-%.0s' {1..79}; echo  # print 79 -
                                exec "${scriptpath}/$scriptfile" "${args[@]}"
                            else
                                syslog_set warn "$script update to $tag had errors"
                            fi
                        fi
                    else
                        echo -e "${Error}ERROR${Off}"\
                            "/tmp/$script-$shorttag.tar.gz not found!"
                        #ls /tmp | grep "$script"  # debug
                        syslog_set warn "/tmp/$script-$shorttag.tar.gz not found"
                    fi
                fi
                cd "$scriptpath" || echo -e "${Error}ERROR${Off} Failed to cd to script location!"
            else
                echo -e "${Error}ERROR${Off} Failed to cd to /tmp!"
                syslog_set warn "$script update failed to cd to /tmp"
            fi
        fi
    fi
fi

#------------------------------------------------------------------------------
# Functions

load_module(){ 
    if [[ -f $1 ]]; then
        if insmod "$1"; then
            echo "Loaded $1"
        else
            ding
            echo -e "${Error}ERROR${Off} Failed to load $1"
        fi
    else
        ding
        echo -e "${Error}ERROR${Off} Missing file!"
        echo "      $1"
        errors=$(errors +1)
    fi
}

remove_module(){ 
    if [[ $1 ]]; then
        if rmmod "$1"; then
            echo "Removed $1"
        else
            ding
            echo -e "${Error}ERROR${Off} Failed to remove $1"
            errors=$(errors +1)
        fi
    fi
}


#------------------------------------------------------------------------------

# Check script is needed
# unique="synology_geminilakenk_ds425+"
unique=$(synogetkeyvalue /etc/synoinfo.conf unique)
if [[ $unique =~ ^synology_geminilakenk_* ]]; then
    echo -e "unique: $unique"
else
    ding
    echo -e "${Error}ERROR${Off} Wrong Synology model!"
    echo "      $unique"
    exit 1
fi


#------------------------------------------------------------------------------
# Download modules


# Get version of ko module
# modinfo /path/to/your/module.ko


url="https://www.blackvoid.club/content/files/2025/09/x25_hw_transcode_modules.zip"
zipfile="$scriptpath/x25_drivers/x25_hw_transcode_modules.zip"
x25_drivers_dir="$scriptpath/x25_drivers"

if [[ ! -d "$x25_drivers_dir" ]]; then
    mkdir "$x25_drivers_dir"
fi

if cd "$x25_drivers_dir"; then
    # Download and extract zip file if it's missing
    if [[ ! -f "$zipfile" ]]; then
        echo -e "\nDownloading transcode modules" 
        if ! curl -JLO -m 30 --connect-timeout 5 "$url"; then
            ding
            echo -e "${Error}ERROR${Off} Failed to download x25_hw_transcode_modules.zip!"
            exit 1
        else
            if [[ -f "$zipfile" ]]; then
                # Extract zip file
                echo -e "\nExtracting x25_hw_transcode_modules.zip" 
                if ! 7z e "$zipfile" >/dev/null; then
                    ding
                    echo -e "${Error}ERROR${Off} Failed to extract x25_hw_transcode_modules.zip!"
                    exit 1
                fi
            else
                ding
                echo -e "${Error}ERROR${Off} Missing file: x25_hw_transcode_modules.zip"
                exit 1
            fi
        fi
    fi
else
    echo -e "${Error}ERROR${Off} Failed to cd to $x25_drivers_dir!"
fi


#------------------------------------------------------------------------------

errors="0"

if [[ $restore == "yes" ]]; then
    # Remove the good modules
    echo -e "\nRemoving script installed modules:"
    remove_module i915
	remove_module i915-compat
	remove_module intel-gtt
	remove_module ttm
	remove_module drm_buddy
	remove_module drm_display_helper
	remove_module drm_kms_helper
	remove_module drm
	remove_module dmabuf

    # Load default modules
    echo -e "\nLoading default modules:"
    load_module /usr/lib/modules/drm.ko
	load_module /usr/lib/modules/drm_kms_helper.ko
	load_module /usr/lib/modules/i915.ko
else
    # Remove default modules
    echo -e "\nRemoving default modules:"
    remove_module i915
    remove_module drm_kms_helper
    remove_module drm

    # Load the good modules
    echo -e "\nLoading good modules:"
    load_module "$x25_drivers_dir"/dmabuf.ko
    load_module "$x25_drivers_dir"/drm.ko
    load_module "$x25_drivers_dir"/drm_kms_helper.ko
    load_module "$x25_drivers_dir"/drm_display_helper.ko
    load_module "$x25_drivers_dir"/drm_buddy.ko
    load_module "$x25_drivers_dir"/ttm.ko
    load_module "$x25_drivers_dir"/intel-gtt.ko
    load_module "$x25_drivers_dir"/i915-compat.ko
    load_module "$x25_drivers_dir"/i915.ko
fi


if [[ $errors -gt "0" ]]; then
    echo -e "\nFinished with $errors errors"
    exit "$errors"
else
    echo -e "\nFinished"
fi

