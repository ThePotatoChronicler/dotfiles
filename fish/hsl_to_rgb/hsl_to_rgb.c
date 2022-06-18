#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char **argv) {
    if (argc != 4) {
        printf("Not enough arguments!\n");
        return 1;
    }
    float H = (fmod(atof(argv[1]), 360)) / 60.0;
    float S = atof(argv[2]);
    float L = atof(argv[3]);
    float a = 2 * L - 1;
    if (a < 0) {
        a = -a;
    }
    float C = (1 - a) * S;
    float res = fmod(H, 2.0) - 1;
    if (res < 0) {
        res = -res;
    }
    float X = C * (1 - res);

    float R1 = 0;
    float G1 = 0;
    float B1 = 0;
    switch ( (int) floor(H) ) {
        case 0:
            R1 = C;
            G1 = X;
            break;
        case 1:
            R1 = X;
            G1 = C;
            break;
        case 2:
            G1 = C;
            B1 = X;
            break;
        case 3:
            G1 = X;
            B1 = C;
            break;
        case 4:
            R1 = X;
            B1 = C;
            break;
        case 5:
            R1 = C;
            B1 = X;
            break;
    }
    float m = L - C / 2.0;
    int R, G, B;
    R = floor((R1 + m) * 255);
    G = floor((G1 + m) * 255);
    B = floor((B1 + m) * 255);
    printf("%02x%02x%02x", R, G, B);
}
