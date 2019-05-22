//
//  main.cpp
//  cnn_single_func
//
//  Created by Patryk Oleniuk on 17.03.17.
//  Copyright © 2017 Patryk Oleniuk. All rights reserved.
//

#include <iostream>
#include <cmath>
#include <time.h>       /* clock_t, clock, CLOCKS_PER_SEC */
#include "cnn_constants.h"
#include "faces.h"
#include "cnn_utils.hpp"
#include <vector>
#include <math.h>

#include "cnn_constants_5_5.h"

#define DEC_MAX 16

using namespace std;

double convolved1[22][48][48]; //[img_nr][W][H]
double convolved2[22][48][48];
double convolved2_p[22][24][24];
double convolved3[22][24][24];
double convolved4[22][24][24];
double convolved4_p1[22][12][12];
double convolved4_p2[22][6][6];
double convolved5[22][6][6];
double convolved6[22][6][6];

double results[6] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0};

double in_img_test[48][48];
double in_ker_test[8][8];


// function used to flatten the values when quantised
void flatten1( int max_val){
    int size = 48;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved1[i][j][k] > (float)max_val ){
                    convolved1[i][j][k] =(float)max_val;
                }
                else if(convolved1[i][j][k] < -(float)max_val){
                    convolved1[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void flatten2( int max_val){
    int size = 48;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved2_p[i][j][k] > (float)max_val ){
                    convolved2_p[i][j][k] =(float)max_val;
                }
                else if(convolved2_p[i][j][k] < -(float)max_val){
                    convolved2_p[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void flatten3( int max_val){
    int size = 24;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved3[i][j][k] > (float)max_val ){
                    convolved3[i][j][k] =(float)max_val;
                }
                else if(convolved3[i][j][k] < -(float)max_val){
                    convolved3[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void flatten4( int max_val){
    int size = 6;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved4_p2[i][j][k] > (float)max_val ){
                    convolved4_p2[i][j][k] =(float)max_val;
                }
                else if(convolved4_p2[i][j][k] < -(float)max_val){
                    convolved4_p2[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void flatten5( int max_val){
    int size = 6;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved5[i][j][k] > (float)max_val ){
                    convolved5[i][j][k] =(float)max_val;
                }
                else if(convolved5[i][j][k] < -(float)max_val){
                    convolved5[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void flatten6( int max_val){
    int size = 6;
    for(int i=0; i<22; i++){
        for(int j=0;j<size; j++){
            for(int k=0;k<size; k++){
                if(convolved6[i][j][k] > (float)max_val ){
                    convolved6[i][j][k] =(float)max_val;
                }
                else if(convolved6[i][j][k] < -(float)max_val){
                    convolved6[i][j][k] = -(float)max_val;
                }
            }
        }
    }
}

void zero_mem(void){
    //zeroing the memory
    for(int i=0; i<22;i++){
        for(int j=0; j<48; j++){
            for(int k=0; k<48; k++){
                convolved1[i][j][k] = 0.0;
                convolved2[i][j][k] = 0.0;
            }
        }
        
        for(int j=0; j<24; j++){
            for(int k=0; k<24; k++){
                convolved2_p[i][j][k] = 0.0;
                convolved3[i][j][k] = 0.0;
                convolved4[i][j][k] = 0.0;
            }
        }
        
        for(int j=0; j<12; j++){
            for(int k=0; k<12; k++){
                convolved4_p1[i][j][k] = 0.0;
            }
        }
        
        for(int j=0; j<6; j++){
            for(int k=0; k<6; k++){
                convolved4_p2[i][j][k] = 0.0;
                convolved5[i][j][k] = 0.0;
                convolved6[i][j][k] = 0.0;
            }
        }
    }
}

std::vector<double> calculate_emotion(const double * face){
    
        
        // LAYER 1
        for(int i=0; i<22; i++){
            conv2d( (const double *) &face[0], 48, 48, ( double *) &Wc1[i][0][0], 8, 8, (double *) &convolved1[i][0][0], false);
            add_const_( (double *) &convolved1[i][0][0], 48, 48, (const double) bc1[i]);
            ReLU( (double *) &convolved1[i][0][0], 48, 48);
        }
        
        //LAYER 2
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved1[j][0][0], 48, 48, (double *) &Wc2[j][i][0][0], 8, 8, (double *) &convolved2[i][0][0], false);
            }
            max_pool_2x2( (const double *) &convolved2[i][0][0], 48, 48, (double *) &convolved2_p[i][0][0] );
            add_const_( (double *) &convolved2_p[i][0][0], 24, 24, (const double) bc2[i]);
            ReLU( (double *) &convolved2_p[i][0][0], 24, 24);
            
        }
        // convolution 2 fully validated.
        
        // LAYER 3
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved2_p[j][0][0], 24, 24, (double *) &Wc3[j][i][0][0], 8, 8, (double *) &convolved3[i][0][0], false);
            }
            add_const_( (double *) &convolved3[i][0][0], 24, 24, (const double) bc3[i]);
            ReLU( (double *) &convolved3[i][0][0], 24, 24);
        }
    
        // LAYER 4
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved3[j][0][0], 24, 24, (double *) &Wc4[j][i][0][0], 4, 4, (double *) &convolved4[i][0][0], false);
            }
            max_pool_2x2( (const double *) &convolved4[i][0][0], 24, 24, (double *) &convolved4_p1[i][0][0] );
            max_pool_2x2( (const double *) &convolved4_p1[i][0][0], 12, 12, (double *) &convolved4_p2[i][0][0] );
            add_const_( (double *) &convolved4_p2[i][0][0], 6, 6, (const double) bc4[i]);
            ReLU( (double *) &convolved4_p2[i][0][0], 6, 6);
        }
        
        // LAYER 5
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved4_p2[j][0][0], 6, 6, (  double *) &Wc5[j][i][0][0], 4, 4, (double *) &convolved5[i][0][0], false);
            }
            add_const_( (double *) &convolved5[i][0][0], 6, 6, (const double) bc5[i]);
            ReLU( (double *) &convolved5[i][0][0], 6, 6);
        }

        // LAYER 6
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved5[j][0][0], 6, 6, (  double *) &Wc6[j][i][0][0], 4, 4, (double *) &convolved6[i][0][0], false);
            }
            add_const_( (double *) &convolved6[i][0][0], 6, 6, (const double) bc6[i]);
            ReLU( (double *) &convolved6[i][0][0], 6, 6);
        }

        // FULLY_CONNECTED LAYER - Matrix Multiplication
        for(int nc=0; nc<6; nc++){
            for(int i=0; i<22; i++){
                for(int di=0; di<6; di++){
                    for(int dj=0; dj<6; dj++){
                        results[nc] += convolved6[i][di][dj] * Wn6[ (36*i) + (di*6)+dj][nc];
                    }
                }
            }
        }

        
        SoftMax(&results[0], 6);
    
    std::vector<double> result_vect;
    for (int i=0;i<6;i++){
        result_vect.push_back(results[i]);
    }

    zero_mem();
    
    return result_vect;
}

std::vector<double> calculate_emotion_quantised(const double * face){
    
    
    // LAYER 1
    for(int i=0; i<22; i++){
        conv2d( (const double *) &face[0], 48, 48, ( double *) &Wc1_q[i][0][0], 8, 8, (double *) &convolved1[i][0][0], false);
        add_const_( (double *) &convolved1[i][0][0], 48, 48, (const double) bc1_q[i]);
        ReLU( (double *) &convolved1[i][0][0], 48, 48);
    }
    
    // quantisation effect
    flatten1(DEC_MAX);
    
    //LAYER 2
    for(int i=0; i<22; i++){
        for(int j=0; j<22; j++){
            conv2d( (const double *) &convolved1[j][0][0], 48, 48, (double *) &Wc2_q[j][i][0][0], 8, 8, (double *) &convolved2[i][0][0], false);
        }
        max_pool_2x2( (const double *) &convolved2[i][0][0], 48, 48, (double *) &convolved2_p[i][0][0] );
        add_const_( (double *) &convolved2_p[i][0][0], 24, 24, (const double) bc2_q[i]);
        ReLU( (double *) &convolved2_p[i][0][0], 24, 24);
        
    }
    // quantisation effect
    flatten2(DEC_MAX);
    
    // LAYER 3
    for(int i=0; i<22; i++){
        for(int j=0; j<22; j++){
            conv2d( (const double *) &convolved2_p[j][0][0], 24, 24, (double *) &Wc3_q[j][i][0][0], 8, 8, (double *) &convolved3[i][0][0], false);
        }
        add_const_( (double *) &convolved3[i][0][0], 24, 24, (const double) bc3_q[i]);
        ReLU( (double *) &convolved3[i][0][0], 24, 24);
    }
    
    // quantisation effect
    flatten3(DEC_MAX);
    
    // LAYER 4
    for(int i=0; i<22; i++){
        for(int j=0; j<22; j++){
            conv2d( (const double *) &convolved3[j][0][0], 24, 24, (double *) &Wc4_q[j][i][0][0], 4, 4, (double *) &convolved4[i][0][0], false);
        }
        max_pool_2x2( (const double *) &convolved4[i][0][0], 24, 24, (double *) &convolved4_p1[i][0][0] );
        max_pool_2x2( (const double *) &convolved4_p1[i][0][0], 12, 12, (double *) &convolved4_p2[i][0][0] );
        add_const_( (double *) &convolved4_p2[i][0][0], 6, 6, (const double) bc4_q[i]);
        ReLU( (double *) &convolved4_p2[i][0][0], 6, 6);
    }
    
    // quantisation effect
    flatten4(DEC_MAX);
    
    // LAYER 5
    for(int i=0; i<22; i++){
        for(int j=0; j<22; j++){
            conv2d( (const double *) &convolved4_p2[j][0][0], 6, 6, (  double *) &Wc5_q[j][i][0][0], 4, 4, (double *) &convolved5[i][0][0], false);
        }
        add_const_( (double *) &convolved5[i][0][0], 6, 6, (const double) bc5_q[i]);
        ReLU( (double *) &convolved5[i][0][0], 6, 6);
    }
    
    // quantisation effect
    flatten5(DEC_MAX);
    
    // LAYER 6
    for(int i=0; i<22; i++){
        for(int j=0; j<22; j++){
            conv2d( (const double *) &convolved5[j][0][0], 6, 6, (  double *) &Wc6_q[j][i][0][0], 4, 4, (double *) &convolved6[i][0][0], false);
        }
        add_const_( (double *) &convolved6[i][0][0], 6, 6, (const double) bc6_q[i]);
        ReLU( (double *) &convolved6[i][0][0], 6, 6);
    }
    
    // quantisation effect
    flatten6(DEC_MAX);
    
    // FULLY_CONNECTED LAYER - Matrix Multiplication
    for(int nc=0; nc<6; nc++){
        for(int i=0; i<22; i++){
            for(int di=0; di<6; di++){
                for(int dj=0; dj<6; dj++){
                    results[nc] += convolved6[i][di][dj] * Wn6_q[ (36*i) + (di*6)+dj][nc];
                }
            }
        }
    }
    
    
    SoftMax(&results[0], 6);
    
    std::vector<double> result_vect;
    for (int i=0;i<6;i++){
        result_vect.push_back(results[i]);
    }
    
    zero_mem();
    
    return result_vect;
}




int main(int argc, const char * argv[]) {
    
    std::vector<std::vector<double>> results_all_original;
    std::vector<std::vector<double>> results_all_quantised;
    double error_sum=0;
    double error_max=0;
    
    //calculating the error
    for(int i=0; i<32; i++){
        results_all_original.push_back(calculate_emotion(faces[i]));
        results_all_quantised.push_back(calculate_emotion_quantised((faces[i])));
        for (int j = 0; j<6;j++){
            double err = abs(results_all_original[i][j] - results_all_quantised[i][j]);
            error_sum += err / 6; // adding the average error
            // looking for the maximum
            if(error_max < err)
                error_max = err;
        }
    }

    printf("\nERROR MEAN IS %f\n", error_sum/32);
    printf("\nERROR MAX IS %f\n", error_max);
    
    return 0;
}
