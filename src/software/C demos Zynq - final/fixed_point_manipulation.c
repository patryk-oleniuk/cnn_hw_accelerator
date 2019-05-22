#include <iostream>
using namespace std;

#define FIXED_BITS ((8))
#define SIZE_MASK 0xFFF
#define MAX_FIXED 0x7FF
#define MIN_FIXED 0x800
#define ONE ((1 << FIXED_BITS))


int toFixed_point( double val ) {
     	if(val > 7.99){
     		return MAX_FIXED;
     	}
     	if(val < -7.99){
     		return MIN_FIXED;
     	}
        return ((int) (val * ONE)) & SIZE_MASK;
};

double to_doubleVal( int fixed_point ) {
     	if(fixed_point & 0x800){ // if negative
     		fixed_point = (fixed_point & SIZE_MASK) + 0xFFFFF000;
     	}
        return ((double) fixed_point) / ONE;
};

int main() {
		
		int f1;

		double start = -0.1;
        for (int i = 0; i<40; i++){
        	f1 = toFixed_point( start );
        	printf( "f1: %f, repr as int: %3x, coming back %f \n", start, f1, to_doubleVal( f1 ) );
        	start += 0.01;
        }

        

	return 0;
}