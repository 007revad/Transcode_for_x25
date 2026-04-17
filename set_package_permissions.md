## How to set the package permissions

There are 2 ways you can set the required permissions for the package.

### Set package permissions via SSH

```
sudo -i
echo "Synospeedtest ALL=(Synospeedtest) NOPASSWD: /var/packages/Synospeedtest/target/bin/speedtest.sh" > /etc/sudoers.d/Synospeedtest
chmod 0440 /etc/sudoers.d/Synospeedtest
cat /etc/sudoers.d/Synospeedtest
```

### Set package permissions in Synology Task Scheduler

1. Go to **Control Panel** > **Task Scheduler** > click **Create** > and select **Scheduled Task**.
2. Select **User-defined script**.
3. Enter a task name.
4. Select **root** as the user (The speedtest binary needs to run with elevated permissions).
5. Untick **Enable** so it does **not** run on a schedule.
6. Click **Task Settings**.
7. In the box under **User-defined script** copy and paste the following. 
    ```
    pkg=Synospeedtest
    file=/etc/sudoers.d/Synospeedtest
    script=/var/packages/Synospeedtest/target/bin/speedtest.sh
    echo "$pkg ALL=($pkg) NOPASSWD: $script" > "$file"
    chmod 0440 "$file"
    cat "$file"
    ```
8. Click **OK** to save the settings.
9. Click on the task - but **don't** enable it - then click **Run**.
10. Once the script has run you can delete the task, or keep in case you need it again.

**Here's some screenshots showing what needs to be set:**

<p align="center">Step 1</p>
<p align="center"><img src="images/sudoers1.png"></p>

<p align="center">Step 2</p>
<p align="center"><img src="images/sudoers2.png"></p>

<p align="center">Step 3</p>
<p align="center"><img src="images/sudoers3-updated.png"></p>

<p align="center">Step 4</p>
<p align="center"><img src="images/sudoers4.png"></p>
