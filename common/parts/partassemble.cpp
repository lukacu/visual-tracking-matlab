
// mex -L . -lpatches histassemble.cpp
// gcc -I /opt/matlab/extern/include -L/opt/matlab/bin/glnx86 -lmx -lmex -lmat -lm patches.cpp -shared -o libpatches.so -L .

#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <string>
#include "mex.h"
#include "matrix.h"
#include "patches.cpp"

using namespace std;

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ) {
	int N_dims, W, H, N;

	if( nrhs < 3 ) mexErrMsgTxt("Three input argument required.");
	if( nlhs < 1 ) mexErrMsgTxt("One output argument required.");

	if (mxGetClassID(prhs[0]) != mxUINT8_CLASS)
		mexErrMsgTxt("The first input image must be uint8");
	
	if (mxGetClassID(prhs[1]) != mxINT32_CLASS)
		mexErrMsgTxt("The second input matrix must be int32");

	N_dims = mxGetNumberOfDimensions(prhs[0]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	H = mxGetM(prhs[0]);
	W = mxGetN(prhs[0]);

	N_dims = mxGetNumberOfDimensions(prhs[1]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	N = mxGetM(prhs[1]);
	if (mxGetN(prhs[1]) != 4)
		mexErrMsgTxt("Four coordinates required");

	int bins = (int)mxGetScalar(prhs[2]);
	int *points = (int*)mxGetPr(prhs[1]);

    plhs[0] = mxCreateCellMatrix(N, 1);

    if (bins > 1) {

	    double *histogram = new double[bins];

        unsigned char * input = (unsigned char *)mxGetData(prhs[0]);

	    for (int i = 0; i < N; i++) { 
		    int rX = points[i]-1;
		    int rY = points[i+N]-1;
		    int rW = points[i+N*2];
		    int rH = points[i+N*3];

	        mxArray * mHist = mxCreateDoubleMatrix(bins, 1, mxREAL);
	        double *result = (double*) mxGetPr(mHist);

		    for (int j = 0; j < bins; j++)
			    histogram[j] = 0;

            if (assemble_histogram(input, W, H, rX, rY, rW, rH, histogram, bins)) {
                for (int j = 0; j < bins; j++) {
                    result[j] = histogram[j];
                }

                mxSetCell(plhs[0], i, mHist);
            }

	    }

	    delete [] histogram;

    } else {
        // Cross-correlation, SSD, or NCC

        unsigned char * input = (unsigned char *)mxGetData(prhs[0]);

	    for (int i = 0; i < N; i++) {
		    int rX = points[i]-1;
		    int rY = points[i+N]-1;
		    int rW = points[i+N*2];
		    int rH = points[i+N*3];

	        mxArray * mPatch = mxCreateDoubleMatrix(rW * rH, 1, mxREAL);
	        double *result = (double*) mxGetPr(mPatch);

		    if (assemble_patch(input, W, H, rX, rY, rW, rH, result))
                mxSetCell(plhs[0], i, mPatch);
	    }

    }

}

