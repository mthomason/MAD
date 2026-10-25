//
//  madpng.c
//  MAD
//
//  Created by Michael Thomason on 5/22/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include "madpng.h"

//#import <MADBarcodes/png.h>
//#import <setjmp.h>
/*
typedef struct _iodata_stream {
    unsigned int  i;
    char         *m;
} iodata_stream;

static void mad_png_read_fn(png_structp ps, png_bytep obuffer, png_size_t z) {
    png_voidp io_ptr = png_get_io_ptr(ps);
    memcpy(obuffer, (((iodata_stream *)io_ptr)->m) + (((iodata_stream*)io_ptr)->i), z);
    ((iodata_stream *)io_ptr)->i += (unsigned int)z;
}

static void png_error_func(png_structp png_ptr, png_const_charp message) {
    //NSLog(@"PNG: %s", message);
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warn_func(png_structp png_ptr, png_const_charp message) {
    //NSLog(@"%s", message);
}

int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length);
int process_data(png_structp *png_ptr, png_infop *info_ptr,
                 png_bytep buffer, png_uint_32 length) {
    if (setjmp(png_jmpbuf((*png_ptr)))) {
        // Free the png_ptr and info_ptr memory on error
        png_destroy_read_struct(png_ptr, info_ptr, NULL);
        return (-1);
    }
    return (0);
}

void info_callback(png_structp png_ptr, png_infop info);
void info_callback(png_structp png_ptr, png_infop info) { }

void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass);
void row_callback(png_structp png_ptr, png_bytep new_row, png_uint_32 row_num, int pass) { }

void end_callback(png_structp png_ptr, png_infop info);
void end_callback(png_structp png_ptr, png_infop info) { }

typedef struct png_control {
    png_structp png_ptr;
    png_infop   info_ptr;
    png_voidp   error_buf;           // Always a jmp_buf at present.
    
    png_const_bytep memory;          // Memory buffer.
    png_size_t      size;            // Size of the memory buffer.
    
    unsigned int for_write       :1; // Otherwise it is a read structure
    unsigned int owned_file      :1; // We own the file in io_ptr
} png_control;
*/
