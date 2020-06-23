#include <Headers/Services/osservice.h>
#include <unistd.h>
#include <linux/reboot.h>
#include <sys/reboot.h>

OsService::OsService() {

}

void OsService::shutdown() {
    reboot(LINUX_REBOOT_CMD_POWER_OFF);
}

void OsService::restart() {
    reboot(LINUX_REBOOT_CMD_RESTART);
}
