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
#include "example_face.h"
#include "cnn_utils.hpp"

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

int main(int argc, const char * argv[]) {
    clock_t t;
    cout << "START" <<endl;
    
    // number of algorithm repetitions for time avg
    int N = 10;

    t = clock();
    
    for(int k =0; k<N;k++){
        
    // LAYER 1
    for(int i=0; i<22; i++){
        conv2d( (const double *) &face1[0][0], 48, 48, ( double *) &Wc1[i][0][0], 8, 8, (double *) &convolved1[i][0][0], false);
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
        cout<<endl;
        for(int i=0; i<6; i++)
            cout<<" "<<results[i];
    }
    
    t = clock() - t;
    printf("Average of clks to for the CNN algorithm : %u \n", (unsigned int) t/N );
    printf("Average execution time of the algorithm : %15f seconds \n", ((float)t)/CLOCKS_PER_SEC/N );

    cout<<endl;

    std::string emotions[6];
    emotions[0]="angry";
    emotions[1]="scared";
    emotions[2]="happy";
    emotions[3]="sad";
    emotions[4]="surpr";
    emotions[5]="normal";
    
    // showing result as a graphical interface
    for(int nc=0; nc<6; nc++){
        printf("%s \t %3.2f : ", emotions[nc].c_str(), results[nc]);
        for(double j=0; j<1.0; j+= 0.04/ results[nc])
            printf("+");
        printf("\n");
    }
    
    return 0;
}
