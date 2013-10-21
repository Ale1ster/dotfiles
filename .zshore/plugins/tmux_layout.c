/* 
 * .: Tmux window layout generator. Receives a layout description and a list of pane ids, and generates a layout string compatible for use with select-layout option.
 * 
 * ?: Aristoteles Panaras "ale1ster"
 * @: 2013-10-21T09:23:31 EEST
 * 
 */

#include <stdio.h>

int main (int argc, char **argv) {
	size_t i;
	for (i=0; i<argc; i++) {
		printf("[%u]:%s,", i, argv[i]);
	}
	printf("\n");
	return 0;
}
