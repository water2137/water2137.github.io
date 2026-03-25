/* cc0 - no rights reserved */

#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#define COUNTS 100

static const char digits[] = "0001020304050607080910111213141516171819"
							 "2021222324252627282930313233343536373839"
							 "4041424344454647484950515253545556575859"
							 "6061626364656667686970717273747576777879"
							 "8081828384858687888990919293949596979899";

int fast_utoa64(uint64_t value, char *buffer)
{
	int len = 1;
	uint64_t temp = value;
	if (temp >= 10000000000000000ULL)
	{
		temp /= 10000000000000000ULL;
		len += 16;
	}
	if (temp >= 100000000ULL)
	{
		temp /= 100000000ULL;
		len += 8;
	}
	if (temp >= 10000ULL)
	{
		temp /= 10000ULL;
		len += 4;
	}
	if (temp >= 100ULL)
	{
		temp /= 100ULL;
		len += 2;
	}
	if (temp >= 10ULL)
	{
		len += 1;
	}
	if (temp == 0ULL)
	{
		buffer[0] = '0';
		return 1;
	}

	char *p = buffer + len;

	while (value >= 100)
	{
		const uint64_t i = (value % 100) * 2;
		value /= 100;
		*--p = digits[i + 1];
		*--p = digits[i];
	}

	if (value < 10)
	{
		*--p = (char)('0' + value);
	}
	else
	{
		const uint64_t i = value * 2;
		*--p = digits[i + 1];
		*--p = digits[i];
	}

	return len;
}

int main(int argc, char **argv)
{
	(void)argc;
	uint64_t i = 1;
	uint64_t count = COUNTS;
	char count_buffer[20];
	pid_t pid;
	char *buffer;

	char filename[] = "/tmp/FIZZBUZZ.XXXXXX";
	int fd = mkstemp(filename);
	if (fd == -1)
	{
		perror("mkstemp");
		exit(EXIT_FAILURE);
	}

	FILE *file = fdopen(fd, "w");
	if (!file)
	{
		perror("fdopen tmpfile");
		exit(EXIT_FAILURE);
	}

	fwrite("#include<unistd.h>\nint main(void)\n{\n\tint w_out = write(1, \"",
		   1, 59, file);

	for (; i <= COUNTS; i++)
	{
		int do_number = 1;
		if (i % 3 == 0)
		{
			do_number = 0;
			fwrite("fizz", 4, 1, file);
			count += 4;
		}
		if (i % 5 == 0)
		{
			do_number = 0;
			fwrite("buzz", 4, 1, file);
			count += 4;
		}
		if (do_number)
		{
			int fast = fast_utoa64(i, count_buffer);
			fwrite(count_buffer, fast, 1, file);
			count += fast;
		}
		fwrite("\\n", 1, 2, file);
	}

	i = fast_utoa64(count, count_buffer);

	buffer = malloc(23 + i);
	if (!buffer)
	{
		perror("malloc");
	}

	memcpy(buffer, "\", ", 3);
	memcpy(buffer + 3, count_buffer, i);
	memcpy(buffer + i + 3, ");\n\treturn w_out;\n}\n", 20);

	fwrite(buffer, 23 + i, 1, file);

	fclose(file);
	free(buffer);

	pid = vfork();
	switch (pid)
	{
	case -1: // failure
		perror("fork");
		exit(EXIT_FAILURE);
	case 0: // child
		execl("/usr/bin/cc", "cc", "-x", "c", filename, "-O3", "-s", "-march=native",
			  "-o", argv[0], NULL);
		perror("execl");
		_exit(EXIT_FAILURE);
	default: // parent
	{
		siginfo_t info;

		if (waitid(P_PID, pid, &info, WEXITED) == -1)
		{
			perror("waitid");
			exit(EXIT_FAILURE);
		}

		if (info.si_code == CLD_EXITED && info.si_status == EXIT_FAILURE)
		{
			i = write(1, "child is exit_failure\n", 22);
			exit(EXIT_FAILURE);
		}
		
		unlink(filename);

		execl(argv[0], argv[0], NULL);
		perror("execl");
	}
	}

	return EXIT_FAILURE;
}
