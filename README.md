# Transcode for x25

<a href="https://github.com/007revad/Transcode_for_x25/releases"><img src="https://img.shields.io/github/release/007revad/Transcode_for_x25.svg"></a>
![Badge](https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2F007revad%2FTranscode_for_x25&label=Visitors&icon=github&color=%23198754&message=&style=flat&tz=Australia%2FSydney)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/007revad)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
<!-- [![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad) -->

### Description

Installs the modules needed for Plex or Jellyfin hardware transcoding in DS425+ and DS225+ that Synology removed to save 20 cents per year.

The script automates the steps outlined by Luka Manestar on Blackvoid.club here: [Unlocking plex HW transcoding on X25 Synology models](https://www.blackvoid.club/unlocking-plex-hw-transcoding-on-x25-synology-models/)

### What the script does

1. Checks it is running as root.
2. Checks it is running on a Synology model that needs it (synology_geminilakenk).
3. Checks if there is a newer version of this script available.
4. Creates a **x25_drivers** folder in the same folder as the script (if the folder does not already exist).
5. Downloads **x25_transcode_modules.zip** from blackvoid and saves it in the **x25_drivers folder** (if the zip file does not already exist).
6. Unzips the downloaded zip file (if the script downloaded the zip file).
7. Removes the default driver modules.
8. Install the working driver modules.

On subsequent runs steps 4, 5 and 6 would be skipped (because the **x25_drivers** folder and **x25_transcode_modules.zip** file already exist).

### Options when running the script

There are optional flags you can use when running the script:

```
Options:
  -h, --help            Show this help message
  -v, --version         Show the script version
  -r, --restore         Restore default modules
      --autoupdate=AGE  Auto update script (useful when script is scheduled)
                          AGE is how many days old a release must be before
                          auto-updating. AGE must be a number: 0 or greater
```

### Download the script

1. Download the latest version _Source code (zip)_ from https://github.com/007revad/Transcode_for_x25/releases
2. Save the download zip file to a folder on the Synology.
3. Unzip the zip file.

### To run the script via task scheduler

You need to schedule this script to run as root at boot. It needs to run every time the NAS boots up.

See [How to schedule](https://github.com/007revad/Transcode_for_x25/blob/main/how_to_schedule.md)

### To run the script via SSH

Note: If you have scheduled the script to run as root at boot-up you don't need to run the script via SSH.

[How to enable SSH and login to DSM via SSH](https://kb.synology.com/en-global/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet)

```YAML
sudo -s /volume1/scripts/transcode_for_x25.sh
```

**Note:** Replace /volume1/scripts/ with the path to where the script is located.

### Troubleshooting

If the script won't run check the following:

1. Make sure you download the zip file and unzipped it to a folder on your Synology (not on your computer).
2. If the path to the script contains any spaces you need to enclose the path/scriptname in double quotes:
   ```YAML
   sudo -s "/volume1/my scripts/transcode_for_x25.sh"
   ```
3. Make sure you unpacked the zip or rar file that you downloaded and are trying to run the transcode_for_x25.sh file.
4. Set the script file as executable:
   ```YAML
   sudo chmod +x "/volume1/scripts/transcode_for_x25.sh"
   ```

### Screenshots

<p align="center">Running script via SSH</p>
<p align="center"><img src="/images/image1.png"></p>

<br>

<p align="center">Plex HW Transcoding working</p>
<p align="center"><img src="/images/working.png"></p>
