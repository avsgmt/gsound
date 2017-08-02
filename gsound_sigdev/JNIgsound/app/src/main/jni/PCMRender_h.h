//
//  PCMRender.h
//  gsound_test
//
//  Created by 王逸凡 on 2017/5/9.
//  Copyright © 2017年 wyf. All rights reserved.
//

#ifndef PCMRender_h_h
#define PCMRender_h_h

#include <stdio.h>
typedef float Float32;
typedef unsigned int UInt32;
typedef unsigned short unichar;


void makeChirp_h(Float32 buffer[],UInt32 freqArray[], int freqArrayLength, double duration_secs,int sample_rate, int channels);
int addWAVHeader_h(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels,UInt32 dataByteSize);
int char_to_freq_h(char c, UInt32 *f);


#endif /* PCMRender_h_h */
