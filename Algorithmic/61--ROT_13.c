#include <stdlib.h>
#include <string.h>

#define UPPERCASE(x) x > 64 && x < 91 
#define LOWERCASE(x) x > 96 && x < 122

char rotate_letter(char c) {
    if(UPPERCASE(c)) return ((c - 65 + 13) % 26) + 65;
    if(LOWERCASE(c)) return ((c - 97 + 13) % 26) + 97;
    return c;
}

char* ROT13(char* txt) {
    size_t len = strlen(txt);
    char* rotated = calloc(len, sizeof(char));
    for(size_t idx = 0; idx < len; ++idx) {
        rotated[idx] = rotate_letter(txt[idx]);
    }
    return rotated;
}
