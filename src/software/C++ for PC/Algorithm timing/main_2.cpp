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


void calculate_emotion(const double * face){
    
    
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
    
    return result_vect;
    
    
}



int main_2(int argc, const char * argv[]) {
    
    // filling img with excel 169, 170 ...; 224, 225 ...; 279...
    /*for(int i=0; i<48; i++){
     for( int j=0; j<48; j++){
     in_img_test[i][j] = (3+i)*55+j+4; // just to reproduce the values on excel
     
     }
     }
     
     
     // filling test kernel with all 1's
     for(int i=0; i<8; i++){
     for( int j=0; j<8; j++){
     in_ker_test[i][j] = 1.0;
     
     }
     }
     
     conv2d((const double *) &in_img_test[0][0], 48, 48, ( double *) &in_ker_test[0][0], 8, 8, (double *) &convolved1[0][0][0], false);
     
     
     
     */
    
    clock_t t, times_layers[7], time_max_s, time_max=0, time_max2=0;
    
    
    cout << "START" <<endl;
    
    // number of algorithm repetitions for time avg
    int N = 1;
    
    t = clock();
    
    for(int k =0; k<N;k++){
        
        // LAYER 1
        for(int i=0; i<22; i++){
            conv2d( (const double *) &faces[0][0], 48, 48, ( double *) &Wc1[i][0][0], 8, 8, (double *) &convolved1[i][0][0], false);
            add_const_( (double *) &convolved1[i][0][0], 48, 48, (const double) bc1[i]);
            ReLU( (double *) &convolved1[i][0][0], 48, 48);
        }
        
        times_layers[0] = clock() - t;
        t = clock();
        
        //LAYER 2
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved1[j][0][0], 48, 48, (double *) &Wc2[j][i][0][0], 8, 8, (double *) &convolved2[i][0][0], false);
            }
            time_max_s = clock();
            max_pool_2x2( (const double *) &convolved2[i][0][0], 48, 48, (double *) &convolved2_p[i][0][0] );
            add_const_( (double *) &convolved2_p[i][0][0], 24, 24, (const double) bc2[i]);
            ReLU( (double *) &convolved2_p[i][0][0], 24, 24);
            time_max += clock() - time_max_s;
            
        }
        time_max_s =0;
        times_layers[1] = clock() - t;
        t = clock();
        // convolution 2 fully validated.
        
        // LAYER 3
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved2_p[j][0][0], 24, 24, (double *) &Wc3[j][i][0][0], 8, 8, (double *) &convolved3[i][0][0], false);
            }
            add_const_( (double *) &convolved3[i][0][0], 24, 24, (const double) bc3[i]);
            ReLU( (double *) &convolved3[i][0][0], 24, 24);
        }
        
        times_layers[2] = clock() - t;
        t = clock();
        // LAYER 4
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved3[j][0][0], 24, 24, (double *) &Wc4[j][i][0][0], 4, 4, (double *) &convolved4[i][0][0], false);
            }
            time_max_s =clock();
            max_pool_2x2( (const double *) &convolved4[i][0][0], 24, 24, (double *) &convolved4_p1[i][0][0] );
            max_pool_2x2( (const double *) &convolved4_p1[i][0][0], 12, 12, (double *) &convolved4_p2[i][0][0] );
            add_const_( (double *) &convolved4_p2[i][0][0], 6, 6, (const double) bc4[i]);
            ReLU( (double *) &convolved4_p2[i][0][0], 6, 6);
            time_max2 += clock() -time_max_s;
        }
        times_layers[3] = clock() - t;
        t = clock();
        
        // LAYER 5
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved4_p2[j][0][0], 6, 6, (  double *) &Wc5[j][i][0][0], 4, 4, (double *) &convolved5[i][0][0], false);
            }
            add_const_( (double *) &convolved5[i][0][0], 6, 6, (const double) bc5[i]);
            ReLU( (double *) &convolved5[i][0][0], 6, 6);
        }
        times_layers[4] = clock() - t;
        t = clock();
        // LAYER 6
        for(int i=0; i<22; i++){
            for(int j=0; j<22; j++){
                conv2d( (const double *) &convolved5[j][0][0], 6, 6, (  double *) &Wc6[j][i][0][0], 4, 4, (double *) &convolved6[i][0][0], false);
            }
            add_const_( (double *) &convolved6[i][0][0], 6, 6, (const double) bc6[i]);
            ReLU( (double *) &convolved6[i][0][0], 6, 6);
        }
        times_layers[5] = clock() - t;
        t = clock();
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
        times_layers[6] = clock() - t;
        t = clock();
        
        SoftMax(&results[0], 6);
        cout<<endl;
        for(int i=0; i<6; i++)
            cout<<" "<<results[i];
    }
    
    double sum=0;
    for(int nc=0; nc<7; nc++){
        sum+= ((float)times_layers[nc])/CLOCKS_PER_SEC/N;
    }
    
    for(int nc=0; nc<7; nc++){
        printf("\n%d: %3.3f perc seconds ",nc,  100* (((float)times_layers[nc])/CLOCKS_PER_SEC/N/sum ));
    }
    
    t = clock() - t;
    printf("Average of clks to for the CNN algorithm : %u \n", (unsigned int) t/N );
    printf("Average execution time of the algorithm : %15f seconds \n", ((float)t)/CLOCKS_PER_SEC/N );
    
    printf("Average of clks from L2 Max: %5f\n", (double)time_max/CLOCKS_PER_SEC );
    printf("Average of clks from L4 Max: %5f\n", (double)time_max2/CLOCKS_PER_SEC );
    
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
