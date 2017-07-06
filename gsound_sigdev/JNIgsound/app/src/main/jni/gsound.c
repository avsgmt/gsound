//
// Created by 王逸凡 on 2017/6/29.
//
#include <string.h>
#include <jni.h>
#include "PCMRender.h"

typedef float Float32;
typedef unsigned int UInt32;
typedef unsigned short unichar;
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
#define DATA_MAX 20

#define SOUND_FILE_PATH "/sdcard/audio.wav"

JNIEXPORT void JNICALL Java_com_shu_wyf_jnigsound_MainActivity_renderChirpData
  (JNIEnv *env, jobject instance){

    /*
     *  序列化字符串转频率
     *  这里原本是要将序列化字符传入的，但是此处将其固定了。
     *  起始音h j，有效字符10个字符，8个校验位，总共20个字符。
     */
    unichar charArray[DATA_MAX] = { 'h', 'j', 'a', 'i', 'a', 'm', 'o', '2', 'k', '4', 'j', '8', '9', 'r', 'i', 'a', 'i', 'h', '8', 'd' };

    UInt32 freqArray[DATA_MAX];//起始音17，19

    for (int i = 0; i<DATA_MAX; i++) {

        char_to_freq(charArray[i], freqArray+i);
    }

    int sampleRate = SAMPLE_RATE;
    float duration = DURATION;
    int channels = 2;//1

    //定义buffer总长度
    UInt32 bufferLength =(UInt32)(duration * sampleRate * (DATA_MAX)* channels);
    printf("+++++++++++bufferLength=%u\n", bufferLength);
//    Float32 buffer[bufferLength];
    Float32 *buffer = (Float32*)malloc(bufferLength * sizeof(Float32));
    memset(buffer, 0, bufferLength*4);
   // printf("+++++++++++sizeof(buffer)=%u\n", sizeof(buffer));
    makeChirp(buffer , freqArray, DATA_MAX, duration, sampleRate, channels);

    unsigned char wavHeaderByteArray[44];
    memset(wavHeaderByteArray, 0, sizeof(wavHeaderByteArray));
    //printf("+++++++++++sizeof wavHeaderByteArray=%u\n", sizeof(wavHeaderByteArray));

    addWAVHeader(wavHeaderByteArray, sampleRate, sizeof(Float32),channels, (bufferLength*sizeof(Float32)));
    for(int k=0;k<44;k++) printf("wavHeaderByteArray[%d]=%c\n",k,wavHeaderByteArray[k]);

    FILE *pFile = fopen(SOUND_FILE_PATH, "wb");
    if (pFile==0) { printf("can't open file\n"); }
    fwrite(wavHeaderByteArray, 1,44, pFile );
    /*
     buffer为数据源地址，size为每个单元的字节数，count为单元个数，stream为文件流指针。
     size_t fwrite(void * buffer, size_t size, size_t count, FILE * stream);
     针对data的buffer数据流，总共写入153820个数据，其中最后20个数据的填充为0，每个数据所占字节数为sizeof(Float32)=4？
     */
    fseek(pFile, sizeof(wavHeaderByteArray), SEEK_CUR);
    fwrite(buffer,sizeof(Float32),bufferLength,pFile);

    fclose(pFile);
    free(buffer);


}