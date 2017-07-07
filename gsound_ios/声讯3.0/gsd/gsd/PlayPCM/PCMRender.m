//
//  PCMRender.m
//  PlayPCM
//
//  Created by hanchao on 13-11-22.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "PCMRender.h"
#import <AudioToolbox/CAFFile.h>


#define SAMPLE_RATE             44100                                                    //采样频率
#define BB_SEMITONE 			1.05946311
#define BB_BASEFREQUENCY		1760
#define BB_BASEFREQUENCY_H		18000
#define BB_BASEFREQUENCY_IS_H	1
#define BB_CHARACTERS			"0123456789abcdefghijklmnopqrstuv"
//#define BB_THRESHOLD            16
#define BITS_PER_SAMPLE         16
#define BB_HEADER_0             17
#define BB_HEADER_1             19
#define DURATION				0.0872 // seconds 0.1744//
#define MAX_VOLUME              0.5
static float frequencies[32];

@implementation PCMRender

#pragma mark -

//wav文件格式详见：http://blog.csdn.net/poechant/article/details/7436710
//wav头的结构如下所示：
typedef   struct   { //
    char         fccID[4];//"RIFF"标志
    unsigned   int       dwSize;//文件长度
    char         fccType[4];//"WAVE"标志
}HEADER;

typedef   struct   { //
    char         fccID[4];//"fmt"标志
    unsigned   int       dwSize;//Chunk size: 16
    unsigned   short     wFormatTag;// 格式类别
    unsigned   short     wChannels;//声道数
    unsigned   int       dwSamplesPerSec;//采样频率
    unsigned   int       dwAvgBytesPerSec;//位速  sample_rate * 2 * chans//为什么乘2呢？因为此时是16位的PCM数据，一个采样占两个byte。
    unsigned   short     wBlockAlign;//一个采样多声道数据块大小
    unsigned   short     uiBitsPerSample;//一个采样占的bit数
}FMT;

typedef   struct   {   //
    char         fccID[4]; 	//数据标记符＂data＂
    unsigned   int       dwSize;//语音数据的长度，比文件长度小36
}DATA;

//添加wav头信息
int addWAVHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels, long dataByteSize)
{
    //以下是为了建立.wav头而准备的变量
    HEADER   pcmHEADER;
    FMT   pcmFMT;
    DATA   pcmDATA;
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
//    strcpy(pcmHEADER.fccID,"RIFF");
    memcpy(pcmHEADER.fccID, "RIFF", sizeof(char)*4);
    pcmHEADER.dwSize=44+dataByteSize;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    memcpy(pcmHEADER.fccType, "WAVE", sizeof(char)*4);
    
    memcpy(buffer, &pcmHEADER, sizeof(pcmHEADER));
    NSLog(@"sizeof pcmHEADER = %lu",sizeof(pcmHEADER));
    
    //以上是创建wav头的HEADER;
    
    //以下是创建wav头的FMT;
//    strcpy(pcmFMT.fccID,"fmt ");
    memcpy(pcmFMT.fccID, "fmt ", sizeof(char)*4);
    pcmFMT.dwSize=16;
    pcmFMT.wFormatTag=3;
    pcmFMT.wChannels=channels;
    pcmFMT.dwSamplesPerSec=sample_rate;
    pcmFMT.dwAvgBytesPerSec=sample_rate * bytesPerSample * channels;//F * M * Nc
    pcmFMT.wBlockAlign=bytesPerSample * channels;//M * Nc
    pcmFMT.uiBitsPerSample=ceil(8 * bytesPerSample);
    
    memcpy(buffer+sizeof(pcmHEADER), &pcmFMT, sizeof (pcmFMT));
   
    NSLog(@"sizeof pcmFMT = %lu",sizeof(pcmFMT));
    //以上是创建wav头的FMT;
    
    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
//    strcpy(pcmDATA.fccID,"data");
    memcpy(pcmDATA.fccID, "data", sizeof(char)*4);
    pcmDATA.dwSize=dataByteSize; //给pcmDATA.dwsize   0以便于下面给它赋值
    
    memcpy(buffer+sizeof(pcmHEADER)+sizeof(pcmFMT), &pcmDATA, sizeof(pcmDATA));
    
    NSLog(@"sizeof pcmDATA = %lu",sizeof(pcmDATA));
    
    return 0;
}

////添加wav头信息
//int addCAFHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels, long dataByteSize)
//{
//    //以下是为了建立.wav头而准备的变量
//    CAFFileHeader   fileHEADER;
//    CAFChunkHeader   chunkHEADER;
//    CAFAudioFormat  audioFormatHEADER;
//    
//    
//    strcpy(fileHEADER.mFileType,"caff");
//    fileHEADER.mFileVersion = 1;
//    fileHEADER.mFileFlags = 0;
//    
//    strcpy(chunkHEADER.mChunkType,"desc");
//    chunkHEADER.mChunkSize = sizeof(CAFAudioFormat);
//    
//    audioFormatHEADER.mSampleRate = 44100;
//    strcpy(audioFormatHEADER.mFormatID,"lpcm");
//    audioFormatHEADER.mFormatFlags = (1L << 0);
//    audioFormatHEADER.mBytesPerPacket =
//    audioFormatHEADER
//    
//
//    
//    return 0;
//}

//添加caf头信息
int addCAFHeader(unsigned char *buffer, int sample_rate, int bytesPerSample, int channels, long dataByteSize)
{
    NSMutableData *headerData = [NSMutableData data];
    // caf header
    CAFFileHeader ch = {kCAF_FileType, kCAF_FileVersion_Initial, 0};
    ch.mFileType = CFSwapInt32HostToBig(ch.mFileType);
    ch.mFileVersion = CFSwapInt16HostToBig(ch.mFileVersion);
    ch.mFileFlags = CFSwapInt16HostToBig(ch.mFileFlags);
//    write(fd, &ch, sizeof(CAFFileHeader));
    [headerData appendBytes:&ch length:sizeof(CAFFileHeader)];
    
    // audio description chunk
    CAFChunkHeader cch;
    cch.mChunkType = CFSwapInt32HostToBig(kCAF_StreamDescriptionChunkID);
    cch.mChunkSize = sizeof(CAFAudioDescription);
    cch.mChunkSize = CFSwapInt64(cch.mChunkSize);
//    write(fd, &cch.mChunkType, sizeof(cch.mChunkType));
    [headerData appendBytes:&cch.mChunkType length:sizeof(cch.mChunkType)];
//    write(fd, &cch.mChunkSize, sizeof(cch.mChunkSize));
    [headerData appendBytes:&cch.mChunkSize length:sizeof(cch.mChunkSize)];
    
    // CAFAudioDescription
    CAFAudioDescription cad;
    CFSwappedFloat64 swapped_sr = CFConvertFloat64HostToSwapped(sample_rate);
    cad.mSampleRate = *((Float64*)(&swapped_sr.v));
    cad.mFormatID = CFSwapInt32HostToBig(kAudioFormatLinearPCM);
    cad.mFormatFlags = 0;
    cad.mFormatFlags |= kCAFLinearPCMFormatFlagIsFloat;
    cad.mFormatFlags = CFSwapInt32HostToBig(cad.mFormatFlags);

    cad.mBytesPerPacket = CFSwapInt32HostToBig(bytesPerSample);
    cad.mFramesPerPacket = CFSwapInt32HostToBig(channels);
    cad.mChannelsPerFrame = CFSwapInt32HostToBig(channels);
    cad.mBitsPerChannel = CFSwapInt32HostToBig(bytesPerSample);
//    write(fd, &cad, sizeof(CAFAudioDescription));
    [headerData appendBytes:&cad length:sizeof(CAFAudioDescription)];
    
    // audio data chunk
    cch.mChunkType = CFSwapInt32HostToBig(kCAF_AudioDataChunkID);
    cch.mChunkSize = (SInt64)CFSwapInt64HostToBig(dataByteSize + sizeof(UInt32));
//    write(fd, &cch.mChunkType, sizeof(cch.mChunkType));
    [headerData appendBytes:&cch.mChunkType length:sizeof(cch.mChunkType)];
//    write(fd, &cch.mChunkSize, sizeof(cch.mChunkSize));
    [headerData appendBytes:&cch.mChunkSize length:sizeof(cch.mChunkSize)];
    
    
//    // audio data
//    UInt32 edit_count = 0;
//    write(fd, &edit_count, sizeof(UInt32));
//    write(fd, samples, samples_size);
    
//    // flush to disk
//    close(fd);
//    
//    // free the samples buffer
//    free(samples);
    
    return 0;
}


#pragma mark - 数字转频率

static int freq_init_flag = 0;
static int freq_init_is_high = 0;

void freq_init() {
	
	if (freq_init_flag) {
		
		return;
	}
    
	//printf("----------------------\n");
	
	int i, len;
	
    if (freq_init_is_high) {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            
            unsigned int freq = (unsigned int)(BB_BASEFREQUENCY_H + (i * 64));
            frequencies[i] = freq;
        }
        
    } else {
        
        for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
            
            unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
            frequencies[i] = freq;
            
        }
    }
    
    freq_init_flag = 1;
}


void switch_freq(int is_high) {
    
    if (is_high == 0 || is_high == 1) {
        
        freq_init_flag = 0;
        freq_init_is_high = is_high;
        
        freq_init();
    }
}

int num_to_freq(int n, unsigned int *f) {
    
    freq_init();
	
	if (f != NULL && n>=0 && n<32) {
		
		*f =  (unsigned int)floor(frequencies[n]);
		
		return 0;
	}
	
	return -1;
}

int char_to_num(char c, unsigned int *n) {
	
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

int char_to_freq(char c, unsigned int *f) {
	
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


void makeChirp(Float32 buffer[],int bufferLength,unsigned int freqArray[], int freqArrayLength, double duration_secs,
               long sample_rate, int bits_persample, int channels) {
    
    double theta = 0;
    int idx = 0;
    NSLog(@"bufferlength = %d,freqArrayLength = %d", bufferLength,freqArrayLength);
    for (int i=0; i<freqArrayLength; i++) {
        
        double theta_increment = 2.0 * M_PI * freqArray[i] / sample_rate;
        
        // Generate the samples
        for (UInt32 frame = 0; frame < (int)(duration_secs * sample_rate); frame++)
//        for (UInt32 frame = 0; frame < (bufferLength / freqArrayLength); frame++)
        {
            Float32 vol = MAX_VOLUME * sqrt( 1.0 - (pow(frame - ((duration_secs * sample_rate) / 2), 2)
                                                    / pow(((duration_secs * sample_rate) / 2), 2)));
            
            buffer[idx++] = vol * sin(theta);
            if(channels == 2)
                buffer[idx++] = vol * sin(theta);
            
            theta += theta_increment;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }
        
    }
    NSLog(@"idx = %d",idx);
    
}

+ (BOOL)isHighFreq {
    
    return !!freq_init_is_high;
}

+ (void)switchFreq:(BOOL)isHigh {

    int is_high = (isHigh ? 1 : 0);
    switch_freq(is_high);
}

+ (NSData *)renderChirpData:(NSString *)serializeStr {
#if 1
    if (serializeStr && serializeStr.length > 0) {
    
        /*
         *  序列化字符串转频率
         */
        unichar *charArray = malloc(sizeof(unichar)*serializeStr.length);
        NSLog(@"length = %d",serializeStr.length);
        [serializeStr getCharacters:charArray];
        
        unsigned freqArray[serializeStr.length+2];//起始音17，19
        //memset(freqArray, 0, sizeof(unsigned) * (serializeStr.length+2));
        
        char_to_freq('h', freqArray);
        char_to_freq('j', freqArray+1);
        
        //freqArray[0] = 123;
        //freqArray[1] = 321;
        
        for (int i=0; i<serializeStr.length; i++) {
            
            //unsigned int freq = 0;
            char_to_freq(charArray[i], freqArray+i+2);
            //freqArray[i+2] = freq;
        }
        
        /*
        for (int i=0; i < 20; i++) {
            
            NSLog(@"%d", freqArray[i]);
        }
         */
        
        free(charArray);
        
        int sampleRate = SAMPLE_RATE;
        float duration = DURATION;
        int channels = 2;//1
        
        //定义buffer总长度
        long bufferLength = (long)(duration * sampleRate * (serializeStr.length+2) * channels);//所有频率总长度(包括17，19)
        NSLog(@"bufferLength = %d",bufferLength);
      
        Float32 buffer[bufferLength];
        memset(buffer, 0, sizeof(buffer));
        
        NSLog(@"sizeof buffer = %d",sizeof(buffer));
        
        makeChirp(buffer, bufferLength, freqArray, serializeStr.length+2, duration, sampleRate, BITS_PER_SAMPLE, channels);
        
        
        unsigned char wavHeaderByteArray[44];
        memset(wavHeaderByteArray, 0, sizeof(wavHeaderByteArray));
        
        addWAVHeader(wavHeaderByteArray, sampleRate, sizeof(Float32), channels, sizeof(buffer));
        
        
        NSMutableData *chirpData = [[NSMutableData alloc] initWithBytes:wavHeaderByteArray length:sizeof(wavHeaderByteArray)];
   
        [chirpData appendBytes:buffer length:sizeof(buffer)];
        
        //return [chirpData autorelease];
        return chirpData;
        
    }
#endif
    return nil;
}



@end
