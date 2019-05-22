//
//  cnn_utils.hpp
//  cnn_single_func
//
//  Created by Patryk Oleniuk on 27.03.17.
//  Copyright © 2017 Patryk Oleniuk. All rights reserved.
//

#ifndef cnn_utils_h
#define cnn_utils_h

//#include <stdio.h>

//
//  cnn_utils.h
//  cnn_single_func
//
//  Created by Patryk Oleniuk on 27.03.17.
//  Copyright © 2017 Patryk Oleniuk. All rights reserved.
//

#ifndef cnn_utils_h
#define cnn_utils_h

//! Modifies the image img - flattens the negative part
//! @param img - 2D image array of the size [img_w][img_h]
void ReLU( double*  img,const unsigned int img_w, const unsigned int img_h);

//! returns for the maximum value from 4 pixels, used for maxpooling
double max_2x2(const double pix1, const double pix2, const double pix3, const double pix4);

//! modifies the x array to be normalized by softmax
//! @param x - 1D array [size] to perform the SoftMax on.
void SoftMax( double * x, unsigned int size);

//! Takes the image, performs the maxpooling operation with the block size (2,2)
//! writing the result to 2x2 smaller image to the out_img pointer
//! @param img - 2D image array of the size [img_w][img_h]
//! @param out_img - 2D image array of the size [img_w/2][img_h/2]
void max_pool_2x2( const double*  img, const unsigned int img_w, const unsigned int img_h, double * out_img);

//!  2D img convolution with a kernel.
//! @param img - 2D image array of the size [img_h][img_w]
//! @param out_img - Result is stored in here ( should have the same size as in_img - [img_h][img_w]);
void conv2d( const double*  img, const unsigned int img_w, const unsigned int img_h,  double * kernel, const unsigned int ker_w, const unsigned int ker_h,
            double * out_img);

//! Adding a constant value for all the pixels in the image
void add_const_( double*  img, const unsigned int img_w, const unsigned int img_h, const double b_const);


#endif /* cnn_utils_h */


#endif /* cnn_utils_h */
