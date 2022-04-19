#include <asm-generic/errno-base.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/resource.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/fcntl.h>

/*
usage : ./plot {<nb> {<commande>}}
*/

void write_plot(const char* filename, unsigned int nb, unsigned int nb_exp, char* argv[])
{
	pid_t pid;
	struct timeval start, end;

	pid_t caught;
	int status;
	struct rusage rusage;

	unsigned long real[nb_exp], cpu[nb_exp], system[nb_exp];

	for (unsigned int j = 0; j < nb_exp; j++) {
		real[j] = 0;
		cpu[j] = 0;
		system[j] = 0;
		for (unsigned int i = 0; i < nb; i++) {
			gettimeofday(&start, NULL);

			pid = fork();
			if (pid < 0) {
				printf("pid < 0 !!!\n");
				return;
			} else if (pid == 0) {
				/* Child */
				int fd = open("/dev/null", O_WRONLY | O_CREAT, 0666); // open the file /dev/null
				dup2(fd, STDOUT_FILENO);
				// dup2(fd, STDERR_FILENO);
				execvp(argv[0], argv);
				printf("Zone normalement non atteinte\n");
				return;
			}
			while ((caught = wait3(&status, 0, &rusage)))
				if (caught == -1) {
					if (errno != ECHILD) {
						perror("caught == -1");
						printf("caught == -1 !!!\n");
						return;
					}
					break;
				}

			gettimeofday(&end, NULL);

			real[j] += (end.tv_sec - start.tv_sec) * 1000000 + end.tv_usec - start.tv_usec;
			cpu[j] += rusage.ru_utime.tv_sec * 1000000 + rusage.ru_utime.tv_usec;
			system[j] += rusage.ru_stime.tv_sec * 1000000 + rusage.ru_stime.tv_usec;
		}
	}

	FILE* fd = fopen(filename, "w");

	for (unsigned int i = 0; i < nb_exp; i++)
		fprintf(fd,
				"%ld.%.6ld\t%ld.%.6ld\t%ld.%.6ld\n",
				real[i] / 1000000,
				real[i] % 1000000,
				cpu[i] / 1000000,
				cpu[i] % 1000000,
				system[i] / 1000000,
				system[i] % 1000000);

	fclose(fd);
}

int main(int argc, char* argv[])
{
	if (argc > 4)
		write_plot(argv[1], atoi(argv[2]), atoi(argv[3]), argv + 4);

	return EXIT_SUCCESS;
}
