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
        unsigned char *pixels = stbi_load(argv[1], &w, &h, &n, 3);
        if(!pixels){
            printf("Error, could not load image!\n");
            return -1;
        }

		unsigned char *data = calloc(w*h, 1);
		for (int i = 0; i < w*h; i++) {
			data[i] = pixels[i * 3] > 128;
		}

        stbi_image_free(pixels);

        struct SDF sdf;
        sdf.w = 192/2;
        sdf.h = 108/2;
        sdf.data = calloc(sdf.w*sdf.h,sizeof(float));
        create_sdf(w,h,data,sdf);


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
