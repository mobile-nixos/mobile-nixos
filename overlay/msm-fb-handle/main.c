#include <fcntl.h>
#include <unistd.h>
#include <assert.h>
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <linux/fb.h>

int main(int argc, char *argv[])
{
	int fd = open("/dev/fb0", O_RDWR);
	setpriority(PRIO_PROCESS, 0, 19);
	assert(fd >= 0);
	while(1) {
		sleep(360000);
	}
	close(fd);
	return 0;
}
