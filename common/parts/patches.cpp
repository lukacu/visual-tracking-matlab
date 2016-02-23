
int assemble_histogram(unsigned char* mat_im, int &W, int &H, int &rX, int &rY, int &rW, int &rH, double* histogram, int&bins)
{
	int rX2 = rX + rW - 1;
	int rY2 = rY + rH - 1;
	int i, j;
	int bin;

    if (rX < 0 || rY < 0 || rX2 >= W || rY2 >= H) {
        return 0;
    }    
    
	rX = (rX < 0) ? 0 : rX;
	rY = (rY < 0) ? 0 : rY;
	rX2 = (rX2 >= W) ? W-1 : rX2;
	rY2 = (rY2 >= H) ? H-1 : rY2;

	for (j = rY ; j <= rY2; j++) {
		for (i = rX ; i <= rX2; i++) {
			bin = (mat_im[j + i * H] * bins) >> 8;
			histogram[bin]++;
		}
	}

    int N = (rX2 - rX + 1) * (rY2 - rY + 1);

	if (N)
		for (i = 0; i < bins; i++)
			histogram[i] /= N;

    return 1;
}

int assemble_patch(unsigned char* mat_im, int &W, int &H, int &rX, int &rY, int &rW, int &rH, double* patch)
{
	int rX2 = rX + rW - 1;
	int rY2 = rY + rH - 1;
	int i, j;
	int bin;

    if (rX < 0 || rY < 0 || rX2 >= W || rY2 >= H) {
        return 0;
    }
    
	rX = (rX < 0) ? 0 : rX;
	rY = (rY < 0) ? 0 : rY;
	rX2 = (rX2 >= W) ? W-1 : rX2;
	rY2 = (rY2 >= H) ? H-1 : rY2;

    if ((rX2 - rX) < rW || (rY2 - rY) < rH) {
        for (i = 0; i < rW * rH; i++) patch[i] = -1;
    }

	for (j = rY ; j <= rY2; j++) {
		for (i = rX ; i <= rX2; i++) {
			patch[(i - rX) + (j - rY) * rW] = (double) mat_im[j + i * H] / 255.0;
		}
	}

    return 1;
}

