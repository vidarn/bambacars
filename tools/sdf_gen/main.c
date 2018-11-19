#include "sdf.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    if(argc == 3){
        int w = 0;
        int h = 0;
        int n = 0;
        unsigned char *data = stbi_load(argv[1], &w, &h, &n, 3);
        if(!data){
            printf("Error, could not load image!\n");
            return -1;
        }

        struct SDF sdf;
        sdf.w = 32;
        sdf.h = 32;
        sdf.data = calloc(sdf.w*sdf.h,sizeof(float));
        create_sdf(w,h,data,sdf);

        stbi_image_free(data);
        for(int i=0;i<sdf.w*sdf.h;i++){
            printf("%f\n",sdf.data[i]);
        }

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
