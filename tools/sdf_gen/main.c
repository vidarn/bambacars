#include "sdf.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    if(argc == 3){
        int w = 32;
        int h = 32;
        struct SDF sdf;
        sdf.w = w;
        sdf.h = h;
        sdf.data = calloc(sdf.w*sdf.h,sizeof(float));

        //create_sdf
        int file_len = 0;
        unsigned char *file_bytes = get_sdf_file_data(sdf, &file_len);
        FILE *fp = fopen(argv[2], "wb");
        if(fp){
            fwrite(file_bytes, 1, file_len, fp);
            fclose(fp);
        }
    }else{
        printf("Error! wrong number of arguments\n");
    }

    return 0;
}
