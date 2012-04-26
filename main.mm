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


#define BUFFER_SIZE			80

int main(int argc, char **argv, char **envp)
{
	int sockfd;
	int readlen;
	char *buffer;

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
		buffer = (char *)malloc(BUFFER_SIZE*sizeof(char));
		memset(buffer, 0, BUFFER_SIZE);
		readlen = read(sockfd, buffer, BUFFER_SIZE-1);

		if (readlen >= BUFFER_SIZE-1) {
			int realloc_count = 1;
			char *realloc_ptr = NULL;
			while (readlen >= BUFFER_SIZE-1) {
				realloc_count++;
				buffer = (char *)realloc(buffer, BUFFER_SIZE*sizeof(char)*realloc_count);
				realloc_ptr = buffer+strlen(buffer);
				readlen = read(sockfd, realloc_ptr, BUFFER_SIZE-1);
				*(realloc_ptr+readlen) = 0x0;
				while (realloc_ptr+readlen != buffer+strlen(buffer)) {
					int i, len = strlen(buffer);
					for (i=-1;*(buffer+len+i)=='\n';i--)
						*(buffer+len+i) = ' ';
					for (i=1;*(buffer+len+i)=='\n';i++)
						*(buffer+len+i) = ' ';
					i--;
					*(buffer+len+i) = '\n';
					if (i != 0)
						*(buffer+len) = ' ';
				}

				if (readlen == 0) break;
			}
		}
		if (readlen == 0) break;

		if (0 == strcmp("\n========================\nASL is here to serve you\n> ", buffer)) {
			strcpy(buffer, "watch");
			write(sockfd, buffer, strlen(buffer)+1);

			free(buffer);
			continue;
		}
		if (0 == strcmp("> ", buffer)) {
			free(buffer);
			continue;
		}

		printf("%s", (buffer[0] == '\n' ? buffer+1 : buffer));

		free(buffer);
	}

	free(buffer);

	close(sockfd);

	puts("end. bye.");

	return 0;
}

// vim:ft=objc
