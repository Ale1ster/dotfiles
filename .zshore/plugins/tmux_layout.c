/* 
 * .: Tmux window layout generator. Receives a layout description and a list of pane ids, and generates a layout string compatible for use with select-layout option.
 * 
 * ?: Aristoteles Panaras "ale1ster"
 * @: 2013-10-21T09:23:31 EEST
 * 
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

size_t layout_checksum (char *layout) {
	size_t csum = 0;
	for (; *layout != '\0'; layout++) {
		csum = (csum >> 1) + ((csum &1) << 15);
		csum += *layout;
	}
	return (csum);
}

int main (int argc, char **argv) {
	// Error out if there is not at least a layout string and at least one pane id.
	if (argc < 3)
		return 1;
	// Layout variables.
	char *old_layout = argv[1];
	size_t new_layout_length = 1024;
	char *new_layout=calloc(new_layout_length, sizeof(char));
	// Initialize the pane_id index (since the first pane_id is argv[2]).
	size_t next_pane = 2, pane_i;
	size_t old_layout_i = 5, new_layout_i = 0, comma_counter = 0;
	// Every 4 consecutive commas substitute the pane id.
	for (; old_layout[old_layout_i] != '\0'; old_layout_i++) {
		switch (old_layout[old_layout_i]) {
			case ',':
				comma_counter++;
				new_layout[new_layout_i++] = ',';
				if (comma_counter == 3) {
					comma_counter = 0;
					// Substitute the next number (pane_id) for the next pane_id in the list.
					while (isdigit(old_layout[old_layout_i+1])) {
						old_layout_i++;
					}
					if (! (next_pane < argc))
						break;
					for (pane_i = 0; argv[next_pane][pane_i] != '\0'; pane_i++) {
						new_layout[new_layout_i++] = argv[next_pane][pane_i];
					}
					next_pane++;
					if (old_layout[old_layout_i+1] == ',') {
						old_layout_i++;
						new_layout[new_layout_i++] = ',';
					}
				}
				break;
			case '{':
			case '}':
			case '[':
			case ']':
				new_layout[new_layout_i++] = old_layout[old_layout_i];
				comma_counter = 0;
				break;
			default	:
				new_layout[new_layout_i++] = old_layout[old_layout_i];
				break;
		}
		// Resize layout string.
		if ((old_layout_i-1) == new_layout_length) {
			new_layout_length*=2;
			new_layout = realloc(new_layout, new_layout_length);
			if (new_layout == NULL)
				return 1;
		}
	}
	new_layout[new_layout_i] = '\0';
	printf("%4x,%s\n", layout_checksum(new_layout), new_layout);
	return 0;
}
