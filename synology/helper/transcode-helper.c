/*
 * transcode-helper.c
 *
 * Narrow setuid-root launcher for Transcode Drivers.
 * Installed with owner root:root, mode 6755 (setuid) by postinst,
 * which itself always runs as root during DSM package install.
 *
 * This replaces the sudoers-based escalation: it does not depend on
 * /usr/bin/sudo being present, and only ever executes one fixed,
 * hardcoded script path with a whitelisted, single argument.
 */

#define _GNU_SOURCE
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifndef TARGET_SCRIPT
#define TARGET_SCRIPT "/var/packages/TranscodeDrivers/target/bin/manage_drivers.sh"
#endif

int main(int argc, char *argv[])
{
    const char *allowed[] = { "start", "stop", NULL };
    if (argc != 2) {
        fprintf(stderr, "transcode-helper: wrong argument count\n");
        return 1;
    }

    int ok = 0;
    for (int i = 0; allowed[i] != NULL; i++) {
        if (strcmp(argv[1], allowed[i]) == 0) { ok = 1; break; }
    }
    if (!ok) {
        fprintf(stderr, "transcode-helper: rejected option '%s'\n", argv[1]);
        return 1;
    }

    /* setuid binary gives us euid=0; promote ruid too so the exec'd
     * script is genuinely root, not just effectively root. */
    if (setuid(0) != 0) { perror("transcode-helper: setuid(0) failed"); return 1; }
    /* Sanitize environment: fixed PATH, no inherited surprises. */
    if (clearenv() != 0) { fprintf(stderr, "transcode-helper: clearenv failed\n"); return 1; }

    setenv("PATH", "/usr/bin:/bin:/usr/sbin:/sbin:/usr/syno/bin:/usr/syno/sbin", 1);
    setenv("HOME", "/root", 1);

    execl(TARGET_SCRIPT, TARGET_SCRIPT, argv[1], (char *)NULL);

    perror("transcode-helper: execl failed");
    return 1;
}