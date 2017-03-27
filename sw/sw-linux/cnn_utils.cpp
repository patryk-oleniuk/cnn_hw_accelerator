//
//  cnn_utils.cpp
//  cnn_single_func
//
//  Created by Patryk Oleniuk on 27.03.17.
//  Copyright © 2017 Patryk Oleniuk. All rights reserved.
//

#include "cnn_utils.hpp"
#include <cmath>

//! Modifies the image img - flattens the negative part
//! @param img - 2D image array of the size [img_w][img_h]
void ReLU( double*  img,const unsigned int img_w, const unsigned int img_h){
    for( int i =0; i<img_h; i++){
        for( int j =0; j<img_w; j++){
            if(img[(i*img_w) + j] < 0){
                img[(i*img_w) + j] = 0.0;
            }
        }
    }
};

//! returns for the maximum value from 4 pixels, used for maxpooling
double max_2x2(const double pix1, const double pix2, const double pix3, const double pix4){
    return fmax(fmax(pix1, pix2), fmax(pix3, pix4));
};

//! modifies the x array to be normalized by softmax
//! @param x - 1D array [size] to perform the SoftMax on.
void SoftMax( double * x, unsigned int size){
    double sum =0;
    for(int i=0; i<size; i++){
        sum += exp(x[i]);
    }
    
    for(int i=0; i<size; i++){
        x[i] = exp(x[i]) / sum;
    }
};

//! Takes the image, performs the maxpooling operation with the block size (2,2)
//! writing the result to 2x2 smaller image to the out_img pointer
//! @param img - 2D image array of the size [img_w][img_h]
//! @param out_img - 2D image array of the size [img_w/2][img_h/2]
void max_pool_2x2( const double*  img, const unsigned int img_w, const unsigned int img_h, double * out_img){
    for( int i =0; i < (img_h); i=i+2){
        for( int j =0; j < (img_w); j=j+2){
            double pix1 = img[ ( i   *img_w) + j   ];
            double pix2 = img[ ( i   *img_w) + j+1 ];
            double pix3 = img[ ((i+1)*img_w) + j   ];
            double pix4 = img[ ((i+1)*img_w) + j+1 ];
            double max_res = max_2x2(pix1, pix2, pix3, pix4);
            unsigned int idx = (i*img_w/4) + (j/2);
            out_img[idx] = max_res;
        }
    }
};

//!  2D img convolution with a kernel.
//! @param img - 2D image array of the size [img_h][img_w]
//! @param out_img - Result is stored in here ( should have the same size as in_img - [img_h][img_w]);
void conv2d( const double*  img, const unsigned int img_w, const unsigned int img_h,  double * kernel, const unsigned int ker_w, const unsigned int ker_h,
            double * out_img, bool print){
    
    int x_ind = 0;
    int y_ind = 0;
    for(int i=0; i< img_h; i++){
        for(int j=0; j< img_w; j++){
            // single kernel operation
            for(int di=0; di< ker_w; di++){
                for(int dj=0; dj< ker_h; dj++){
                    x_ind = i + di-(ker_w/2)+1;
                    y_ind = j + dj-(ker_h/2)+1;
                    if( (x_ind >= 0) && (x_ind<img_w) && (y_ind >= 0) && (y_ind<img_h) ){
                        if(print)
                            printf("%d %d add: %f,  ker = %f \n", x_ind, y_ind, ( img[ (x_ind * img_w) + y_ind ] * kernel[ (di*ker_w) + dj]), kernel[ (di*ker_w) + dj]);
                        out_img[(i*img_w) + j] += ( img[ (x_ind * img_w) + y_ind ] * kernel[ (di*ker_w) + dj] );
                    }
                }
            }
        }
    }
};

//! Adding a constant value for all the pixels in the image
void add_const_( double*  img, const unsigned int img_w, const unsigned int img_h, const double b_const){
    for(int i=0; i< img_w; i++){
        for(int j=0; j< img_h; j++){
            img[(i*img_w) + j] += b_const;
        }
    }
};
