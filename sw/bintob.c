#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[])
{
    FILE *f;
    FILE *g;
    unsigned char data;
    int addr = 0;
    f = fopen(argv[1], "r");
    if (!f)
        return -1;
    g = fopen(argv[2], "w");
    if (!g)
        return -1;
    while (1 == fread(&data, 1, 1, f)) {
        // Verilog case statement
        // printf("    16'h%4.4x: rd_data <= 32'h%8.8x;\n", addr, data);
        // For readmemh
        fprintf(g, "%2.2x\n", data);
        addr++;
    }
    fclose(g);
    fclose(f);
    return 0;
}
