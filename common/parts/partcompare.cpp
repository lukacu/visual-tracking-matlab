
// mex -L . -lpatches -lm histcompare.cpp

#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <string>
#include <math.h>
#include "mex.h"
#include "matrix.h"
#include "patches.cpp"

using namespace std;


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ) {
	int N_dims, W, H, N, M;
	if( nrhs < 4 ) mexErrMsgTxt("Four input argument required.");
	if( nlhs < 1 ) mexErrMsgTxt("One output argument required.");

	/* W, H - image size, B - number of bins, N - number of histograms, M - number of samples per histogram */

	if (mxGetClassID(prhs[0]) != mxUINT8_CLASS) /* Image (grayscale, H x W) */
		mexErrMsgTxt("The first input image must be uint8");
	
	if (mxGetClassID(prhs[1]) != mxCELL_CLASS) /* Parts (N x B) */
		mexErrMsgTxt("The second input image must be cell array");

	if (mxGetClassID(prhs[2]) != mxINT32_CLASS) /* Positions (M x 4 x N) */
		mexErrMsgTxt("The second input image must be int32");

	N_dims = mxGetNumberOfDimensions(prhs[0]);
	if ( N_dims != 2 ) mexErrMsgTxt("The first input image must be single channel");
	H = mxGetM(prhs[0]); // - rows
	W = mxGetN(prhs[0]); // - columns

	int bins = (int)mxGetScalar(prhs[3]);

	N_dims = mxGetNumberOfDimensions(prhs[1]);
	if ( N_dims > 2 ) mexErrMsgTxt("The first input image must be single channel");
	N = mxGetM(prhs[1]);

	N_dims = mxGetNumberOfDimensions(prhs[2]);
	if ( N_dims > 2 ) {
		if (N_dims != 3)
			mexErrMsgTxt("Third image must be 2 or 3 dimensional");
		const mwSize *size = mxGetDimensions(prhs[2]);
		M = size[0];
		if (size[1] != 4)
			mexErrMsgTxt("Four coordinates required");
		if (N != size[2])
			mexErrMsgTxt("Illegal region number");
	} else {
		M = mxGetM(prhs[2]);
		if (mxGetN(prhs[2]) != 4)
			mexErrMsgTxt("Four coordinates required");
		if (N != 1)
			mexErrMsgTxt("Illegal number of regions");
	}

	//double *histograms = (double *)mxGetPr(prhs[1]);
	int *points = (int*)mxGetPr(prhs[2]);

	plhs[0] = mxCreateDoubleMatrix(N, M, mxREAL);
	double *result = (double*) mxGetPr(plhs[0]);

    unsigned char * image = (unsigned char *)mxGetData(prhs[0]);

    if (bins > 0) {

	    double *histogram = new double[bins];

	    for (int k = 0; k < N; k++) {
            mxArray* mHist = mxGetCell (prhs[1], k);
            double *dHist = (double*) mxGetPr(mHist);

		    for (int i = 0; i < M; i++) {
			    int rX = points[i + (k*4*M)]-1;
			    int rY = points[i + (k*4*M)+M]-1;
			    int rW = points[i + (k*4*M)+M*2];
			    int rH = points[i + (k*4*M)+M*3];

			    for (int j = 0; j < bins; j++)
				    histogram[j] = 0;
			    
                
                if (!assemble_histogram(image, W, H, rX, rY, rW, rH, histogram, bins)) {
                    result[k + i*N] = mxGetNaN();
                    continue;
                }
                    
			    double sum = 0;

			    for (int j = 0; j < bins; j++) {
				    sum += sqrt( histogram[j] * dHist[j]);
			    }

			    result[k + i*N] = sum;
		    }
	    }

	    delete [] histogram;

    } else {
        if (bins == 0) { // SSD

	        for (int k = 0; k < N; k++) {
                mxArray* mHist = mxGetCell (prhs[1], k);
                double *dPatch = (double*) mxGetPr(mHist);

		        for (int i = 0; i < M; i++) {
			        int rX = points[i + (k*4*M)]-1;
			        int rY = points[i + (k*4*M)+M]-1;
			        int rW = points[i + (k*4*M)+M*2];
			        int rH = points[i + (k*4*M)+M*3];

	                double *patch = new double[rW * rH];

			        if (!assemble_patch(image, W, H, rX, rY, rW, rH, patch)) {
                        result[k + i*N] = mxGetNaN();
                        continue;
                    }
			        double sum = 0;

			        for (int j = 0; j < rW * rH; j++) {
                        double p1 = patch[j];
                        double p2 = dPatch[j];
                        if (p1 < 0 || p2 < 0) continue;
				        sum += (p1 - p2) * (p1 - p2);
			        }

	                delete [] patch;

			        result[k + i*N] = 1 - sum / (rW * rH);
		        }
	        }

        } else if (bins == -1) { // Cross-correlation

	        for (int k = 0; k < N; k++) {
                mxArray* mHist = mxGetCell (prhs[1], k);
                double *dPatch = (double*) mxGetPr(mHist);

		        for (int i = 0; i < M; i++) {
			        int rX = points[i + (k*4*M)]-1;
			        int rY = points[i + (k*4*M)+M]-1;
			        int rW = points[i + (k*4*M)+M*2];
			        int rH = points[i + (k*4*M)+M*3];

	                double *patch = new double[rW * rH];

			        if (!assemble_patch(image, W, H, rX, rY, rW, rH, patch)) {
                        result[k + i*N] = mxGetNaN();
                        continue;
                    }
			        double sum = 0;

                    double m1 = 0;
                    double m2 = 0;
                    
                    for (int j = 0; j < rW * rH; j++) {
                        double p1 = patch[j];
                        double p2 = dPatch[j];
                        //if (p1 < 0 || p2 < 0) continue;
                        m1 += p1;
                        m2 += p2;
                    }                     
                    
                    m2 /= (double)(rW * rH);
                    m1 /= (double)(rW * rH);
                    
			        for (int j = 0; j < rW * rH; j++) {
                        double p1 = patch[j];
                        double p2 = dPatch[j];
                        //if (p1 < 0 || p2 < 0) continue;
				        sum += (p1 - m1) * (p2 - m2);
                        //sum += p1 * p2;
			        }

	                delete [] patch;

			        result[k + i*N] = sum / (rW * rH);
                    
                    if (result[k + i*N] < 0) result[k + i*N] = 0;
		        }
	        }

        } else { // NCC

	        for (int k = 0; k < N; k++) {
                mxArray* mHist = mxGetCell (prhs[1], k);
                double *dPatch = (double*) mxGetPr(mHist);

		        for (int i = 0; i < M; i++) {
			        int rX = points[i + (k*4*M)]-1;
			        int rY = points[i + (k*4*M)+M]-1;
			        int rW = points[i + (k*4*M)+M*2];
			        int rH = points[i + (k*4*M)+M*3];

	                double *patch = new double[rW * rH];

			        if (!assemble_patch(image, W, H, rX, rY, rW, rH, patch)) {
                        result[k + i*N] = mxGetNaN();
                        continue;
                    }
                    
			        double sum = 0;

                    double m1 = 0;
                    double m2 = 0;
                    
                    for (int j = 0; j < rW * rH; j++) {
                        double p1 = patch[j];
                        double p2 = dPatch[j];
                        if (p1 < 0 || p2 < 0) continue;
                        m1 += p1; m2 += p2;
                    } 

                    m1 /= (double)(rW * rH); m2 /= (double)(rW * rH);

 
                    double d1 = 0;
                    double d2 = 0;
                    
			        for (int j = 0; j < rW * rH; j++) {
                        double p1 = patch[j];
                        double p2 = dPatch[j];
                                              
                        if (p1 < 0 || p2 < 0) continue;
				        sum += (p1 - m1) * (p2 - m2);

                        d1 += (p1 - m1) * (p1 - m1);
                        d2 += (p2 - m2) * (p2 - m2);
			        }

                    //d1 /= (double)(rW * rH); d2 /= (double)(rW * rH);

	                delete [] patch;

			        result[k + i*N] = (sum / sqrt(d1 * d2));
       
                    if (result[k + i*N] < 0) result[k + i*N] = 0;
		        }
	        }


        }

    }

}

