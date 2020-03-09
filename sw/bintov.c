#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[])
{
    FILE *f = fopen(argv[1], "r");
    unsigned data;
    int addr = 0;
    while (1 == fread(&data, 4, 1, f)) {
        printf("    16'h%4.4x: rd_data <= 32'h%8.8x;\n", addr, data);
        addr++;
    }
}
