/***************************************************************************
 * 
 * viewsyslog
 * 
 * display syslog without interaction
 * 
 * 
 * under MIT license
 * 
 * written by deVbug
 * 2012-04-26
 * 
 * References
 * http://theiphonewiki.com/wiki/index.php?title=System_Log
 * and socat source code
 * http://forum.falinux.com/zbxe/?document_srl=406064
 * 
 ***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/socket.h>


int main(int argc, char **argv, char **envp)
{
	int sockfd;
	int readlen;
	char buffer[1025];

	struct sockaddr_un server_addr;

	bzero(&server_addr, sizeof(server_addr));
	server_addr.sun_family = AF_UNIX;
	strcpy(server_addr.sun_path, "/var/run/lockdown/syslog.sock");

	sockfd = socket(PF_LOCAL, SOCK_STREAM, 0);
	if (sockfd < 0) {
		perror("socket error : ");
		exit(0);
	}

	if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
		perror("connect error : ");
		exit(0);
	}

	while (1) {
		memset(buffer, 0, 1025);
		readlen = read(sockfd, buffer, 1024);

		if (readlen == 0) break;

		if (0 == strcmp("\n========================\nASL is here to serve you\n> ", buffer)) {
			strcpy(buffer, "watch");
			write(sockfd, buffer, strlen(buffer)+1);
		}
		if (0 == strcmp("> ", buffer)) continue;

		printf("%s", buffer);
	}

	close(sockfd);

	puts("end. bye.");

	return 0;
}

// vim:ft=objc
