# <img src="images/icon.png" width="40"> Heading goes here

<a href="https://github.com/007revad/REPO_NAME/releases"><img src="https://img.shields.io/github/release/007revad/REPO_NAME.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F007revad%2FREPO_NAME&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=views&edge_flat=false"/></a>
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/007revad)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
[![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad)

### Description

Description goes here

### Download the script

1. Download the latest version _Source code (zip)_ from https://github.com/007revad/REPO_NAME/releases
2. Save the download zip file to a folder on the Synology.
3. Unzip the zip file.

### To run the script via task scheduler

See [How to run from task scheduler](https://github.com/007revad/REPO_NAME/blob/main/how_to_run_from_scheduler.md)

### To run the script via SSH

[How to enable SSH and login to DSM via SSH](https://kb.synology.com/en-global/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet)

```YAML
sudo -s /volume1/scripts/SCRIPT_NAME.sh
```

**Note:** Replace /volume1/scripts/ with the path to where the script is located.

### Troubleshooting

If the script won't run check the following:

1. Make sure you download the zip file and unzipped it to a folder on your Synology (not on your computer).
2. If the path to the script contains any spaces you need to enclose the path/scriptname in double quotes:
   ```YAML
   sudo -s "/volume1/my scripts/SCRIPT_NAME.sh"
   ```
3. Make sure you unpacked the zip or rar file that you downloaded and are trying to run the SCRIPT_NAME.sh file.
4. Set the script file as executable:
   ```YAML
   sudo chmod +x "/volume1/scripts/SCRIPT_NAME.sh"
   ```

### Screenshots

<!--- <p align="center">Description of image 1 goes here</p> --->
<p align="center"><img src="/images/IMAGE_NAME.png"></p>

<br>

<!--- <p align="center">Description of image 2 goes here</p> --->
<p align="center"><img src="/images/IMAGE_NAME.png"></p>
