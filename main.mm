/***************************************************************************
 * 
 * viewsyslog
 * 
 * display syslog
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
 * http://www.ezdoum.com/upload/2/20020519003010/reg.txt
 * 
 ***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/socket.h>
#include <regex.h>


#define BUFFER_SIZE			1024


int readSocket(const int sockfd, char * const buffer, const size_t bufsize)
{
	int readlen = read(sockfd, buffer, bufsize);
	*(buffer+readlen) = '\0';

	while (buffer+readlen != buffer+strlen(buffer)) {
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

	return readlen;
}

char *recvDataToNewBuffer(const int sockfd)
{
	char *buffer = (char *)malloc(BUFFER_SIZE*sizeof(char));
	if (buffer == NULL) return buffer;

	memset(buffer, 0, BUFFER_SIZE);
	int readlen = readSocket(sockfd, buffer, BUFFER_SIZE-1);

	if (readlen >= BUFFER_SIZE-1) {
		int realloc_count = 1;
		char *realloc_ptr = NULL;
		while (readlen >= BUFFER_SIZE-1) {
			realloc_count++;
			buffer = (char *)realloc(buffer, BUFFER_SIZE*sizeof(char)*realloc_count);
			if (buffer == NULL) return buffer;

			realloc_ptr = buffer+strlen(buffer);
			readlen = readSocket(sockfd, realloc_ptr, BUFFER_SIZE-1);

			if (readlen == 0) break;
		}
	}
	if (readlen == 0) {
		free(buffer);
		buffer = NULL;
	}

	return buffer;
}

void printData(char * const buffer, regex_t *filter)
{
	char *line = NULL;

	line = strtok(buffer, "\n");

	while (line != NULL) {
		if (line[0] != '\0' && 0 != strcmp("> ", line)) {
			if (filter == NULL || regexec(filter, line, 0, NULL, 0) == 0)
				puts(line);
		}

		line = strtok(NULL, "\n");
	}
}

int main(int argc, char **argv, char **envp)
{
	int sockfd = -1;
	char *buffer = NULL;
	
	int regex_error = 0;
	regex_t preg;
	BOOL on_regex = NO;

	if (argc > 2) {
		fprintf(stderr, "usage: %s pattern\n", argv[0]);
		exit(1);
	}

	if (argc == 2) {
		// no case test ==> add | REG_ICASE
		if (0 != (regex_error = regcomp(&preg, argv[1], REG_EXTENDED | REG_NOSUB))) {
			fprintf(stderr, "%s: wrong regular expression pattern\n", argv[0]);
			fprintf(stderr, "%s: ignore pattern\n", argv[0]);

			int ret = regerror(regex_error, &preg, NULL, 0);
			char *msg = (char *)malloc(sizeof(char)*ret);
			regerror(regex_error, &preg, msg, ret);
			fprintf(stderr, "%s: %s\n", argv[0], msg);
			free(msg);

			on_regex = NO;
		} else {
			on_regex = YES;
		}
	}

	struct sockaddr_un server_addr;

	bzero(&server_addr, sizeof(server_addr));
	server_addr.sun_family = AF_UNIX;
	strcpy(server_addr.sun_path, "/var/run/lockdown/syslog.sock");

	sockfd = socket(PF_LOCAL, SOCK_STREAM, 0);
	if (sockfd < 0) {
		perror("socket error : ");
		if (on_regex) regfree(&preg);
		exit(0);
	}

	if (connect(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
		perror("connect error : ");
		if (on_regex) regfree(&preg);
		close(sockfd);
		exit(0);
	}

	while (1) {
		buffer = recvDataToNewBuffer(sockfd);
		if (buffer == NULL) break;

		if (0 == strcmp("\n========================\nASL is here to serve you\n> ", buffer)) {
			strcpy(buffer, "watch");
			write(sockfd, buffer, strlen(buffer)+1);

			free(buffer);
			buffer = NULL;
			continue;
		}

		printData(buffer, on_regex ? &preg : NULL);

		free(buffer);
		buffer = NULL;
	}

	if (buffer) free(buffer);

	close(sockfd);

	if (on_regex) regfree(&preg);

	puts("end. bye.");

	return 0;
}

// vim:ft=objc
