//
//  PCMRender.c
//  gsound_test
//
//  Created by 王逸凡 on 2017/5/9.
//  Copyright © 2017年 wyf. All rights reserved.
//
#include "PCMRender.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#define SAMPLE_RATE             44100            //采样率
#define BB_SEMITONE 			1.05946311       //伴音音程
#define BB_BASEFREQUENCY		1760             //低频基础频率
#define BB_BASEFREQUENCY_H		18000            //高频基础频率
#define BB_BASEFREQUENCY_IS_H	1                //高频基础频率标志位
#define BB_CHARACTERS			"0123456789abcdefghijklmnopqrstuv"
#define BITS_PER_SAMPLE         16               //每样本的数据位数
#define BB_HEADER_0             17               //发送头字母0：h
#define BB_HEADER_1             19               //发送头字母1：j
#define DURATION				0.0872           //每一段频率持续时间：87.2ms
#define MAX_VOLUME              0.5

//#define M_PI 3.14159265358979323846264338327950288
typedef float Float32;
typedef unsigned int UInt32;
typedef unsigned short unichar;

static float frequencies[32];                    //频率数组

typedef   struct   {
    char fccID[4];
    UInt32 dwSize;
    char fccType[4];
}HEADER;

typedef   struct   {
    char         fccID[4];
    UInt32       dwSize;
    unsigned   short     wFormatTag;
    unsigned   short     wChannels;
    UInt32       dwSamplesPerSec;
    UInt32       dwAvgBytesPerSec;
    unsigned   short     wBlockAlign;             //数据块的调整数，为（通道数x没样本的数据位值/8），播放软件一次需要处理多个该值大小的字节数据，以便将其值用于缓冲区的调整
    unsigned   short     uiBitsPerSample;         //每样本的数据位数
}FMT;

typedef struct     {
    char         fccID[4];
    UInt32        dwSize;
}DATA;


int addWAVHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels,UInt32 dataByteSize)
{
    //以下是为了建立.wav头而准备的变量
    HEADER   pcmHEADER;
    FMT		 pcmFMT;
    DATA	 pcmDATA;
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    //    strcpy(pcmHEADER.fccID,"RIFF");
    /*void *memcpy(void *dest, const void *src, size_t n);
     从源src所指的内存地址的起始位置开始拷贝n个字节到目标dest所指的内存地址的起始位置中
     如果要追加数据，则每次执行memcpy后，要将目标数组地址增加到你要追加数据的地址。*/
    memcpy(pcmHEADER.fccID, "RIFF", sizeof(char)*4);
    pcmHEADER.dwSize=(44+dataByteSize);   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    memcpy(pcmHEADER.fccType, "WAVE", sizeof(char)*4);
    
    memcpy(buffer, &pcmHEADER, sizeof(pcmHEADER));
    //以上是创建wav头的HEADER;
    
    //以下是创建wav头的FMT;
    //    strcpy(pcmFMT.fccID,"fmt ");
    memcpy(pcmFMT.fccID, "fmt ", sizeof(char)*4);
    /*SubChunkSize为AudioFormat2个字节、NumChannel2个字节、SampleRate4个字节、
     ByteRate4个字节、BlockAlign2个字节、BitsPerSample2个字节
     共计2+2+4+4+2+2=16个字节*/
    pcmFMT.dwSize=16;
    pcmFMT.wFormatTag=1;
    pcmFMT.wChannels=channels;
    pcmFMT.dwSamplesPerSec=sample_rate;
    pcmFMT.dwAvgBytesPerSec=sample_rate * bytesPerSample * channels;//F * M * Nc
    pcmFMT.wBlockAlign=bytesPerSample * channels;//M * Nc
    pcmFMT.uiBitsPerSample=ceil(8 * bytesPerSample);
    
    memcpy(buffer+sizeof(pcmHEADER), &pcmFMT, sizeof (pcmFMT));
    //以上是创建wav头的FMT;
    
    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
    //    strcpy(pcmDATA.fccID,"data");
    memcpy(pcmDATA.fccID, "data", sizeof(char)*4);
    pcmDATA.dwSize=dataByteSize; //给pcmDATA.dwsize   0以便于下面给它赋值
    memcpy(buffer+sizeof(pcmHEADER)+sizeof(pcmFMT), &pcmDATA, sizeof(pcmDATA));
    
    return 0;
}

static int freq_init_flag = 0;
static int freq_init_is_high = 0;

//频率初始化，如果已经初始化过了，则不再初始化。
static void freq_init() {
    
    if (freq_init_flag) {
        
        return;
    }
    
    //printf("----------------------\n");
    /*floor()函数：
     “向下取整”，或者说“向下舍入”，即取不大于x的最大整数*/
    int i, len;
    
    if (freq_init_is_high) {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            //高频段不需要考虑人能够听到的乐理，因此可以间隔小一些？
            //TODO****************
            unsigned int freq = (unsigned int)(BB_BASEFREQUENCY_H + (i * 64));
            frequencies[i] = freq;
        }
        
    } else {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            //根据乐理，音程来对于各个字符数字赋值初始频率。
            unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
            frequencies[i] = freq;
            
        }
    }
    
    freq_init_flag = 1;
}


static void switch_freq(int is_high) {
    
    if (is_high == 0 || is_high == 1) {
        
        freq_init_flag = 0;
        freq_init_is_high = is_high;
        
        freq_init();
    }
}

//数字对应的频率赋值给frequencies数组
static int num_to_freq(int n, UInt32 *f) {
    
    freq_init();
    
    if (f != NULL && n>=0 && n<32) {
        
        *f =  (unsigned int)floor(frequencies[n]);
        
        return 0;
    }
    
    return -1;
}

//字符对应的数字
static int char_to_num(char c, UInt32 *n) {
    
    if (n == NULL) return -1;
    
    *n = 0;
    
    if (c>=48 && c<=57) {
        
        *n = c - 48;
        
        return 0;
        
    } else if (c>=97 && c<=118) {
        
        *n = c - 87;
        
        return 0;
    }
    
    return -1;
}

//字符到频率
int char_to_freq(char c, UInt32 *f) {
    
    unsigned int n;
    
    if (f != NULL && char_to_num(c, &n) == 0) {
        
        unsigned int ff;
        
        if (num_to_freq(n, &ff) == 0) {
            
            *f = ff;
            return 0;
        }
    }
    
    return -1;
}
/*  makeChirp函数的作用为：将频率信息进行采样。然后对声音进行椭圆窗处理。
 比如在我们的例子中，采用了椭圆形窗对声波进行了音量上的优化。
 buffer为缓冲区即data、bufferLength为缓冲区长度、freqArray为频率数组、freqArrayLength为频率数组的长度、
 duration_secs为帧长，即采样时间、sample_rate为采样率、bits_persample为采样位宽、channels为通道数*/
void makeChirp(Float32 buffer[],UInt32 freqArray[], int freqArrayLength, double duration_secs,int sample_rate, int channels) {
    
    double theta = 0;
    int idx = 0;
    //frame_size为帧长，即采样次数。
    double frame_size = duration_secs * sample_rate;
    double frame_size_1_2 = frame_size / 2;
    for (int i=0; i<freqArrayLength; i++) {
        
        double theta_increment = 2.0 * M_PI * freqArray[i] / sample_rate;
        
        for (UInt32 frame = 0; frame < (int)(frame_size); frame++)
        {
            //此处可能进行了量化处理
//            printf("+++++++1+++++++++++i = %d,frame = %d,idx = %ld\n", i, frame, idx);
            Float32 vol = (Float32)(MAX_VOLUME * sqrt(1.0 - (pow(frame - (frame_size_1_2), 2)
                                                   / pow((frame_size_1_2), 2))));
            buffer[idx++] = (Float32)(vol * sin(theta));
//            printf("+++++++2+++++++++++i = %d,frame = %d,idx = %ld\n", i, frame,idx);
            if(channels == 2)
                buffer[idx++] = vol * sin(theta);
//            printf("+++++++3+++++++++++i = %d,frame = %d,idx = %ld\n", i, frame, idx);
            theta += theta_increment;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }
    }
  //  return idx;
}

static _Bool isHighFreq() {
    
    return !!freq_init_is_high;
}

static void switchFreq(_Bool isHigh) {
    
    int is_high = (isHigh ? 1 : 0);
    switch_freq(is_high);
}




