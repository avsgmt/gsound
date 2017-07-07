//
//  AppDelegate.m
//  gsd
//
//  Created by wanli on 17/5/29.
//  Copyright © 2017年 gmt. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioUnit/AudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "bb_freq_util.h"
#import "rscode.h"
#import "PCMRender.h"

#import "FFTBufferManager.h"
#import "aurio_helper.h"
#import "queue.h"
#import "CAXException.h"

typedef enum aurioTouchDisplayMode {
    aurioTouchDisplayModeOscilloscopeWaveform,
    aurioTouchDisplayModeOscilloscopeFFT,
    aurioTouchDisplayModeSpectrum
} aurioTouchDisplayMode;

typedef struct SpectrumLinkedTexture {
    GLuint							texName;
    struct SpectrumLinkedTexture	*nextTex;
} SpectrumLinkedTexture;

@interface AppDelegate ()
{
  //  UIWindow*                   window;
 //   EAGLView*                   view;
    
    UIImageView*				sampleSizeOverlay;
    UILabel*					sampleSizeText;
    
    SInt32*						fftData;
    NSUInteger					fftLength;
    BOOL						hasNewFFTData;
    
    AudioUnit					rioUnit;
    BOOL						unitIsRunning;
    BOOL						unitHasBeenCreated;
    
    BOOL						initted_oscilloscope, initted_spectrum;
    UInt32*						texBitBuffer;
    CGRect						spectrumRect;
    
    GLuint						bgTexture;
    GLuint						muteOffTexture, muteOnTexture;
    GLuint						fftOffTexture, fftOnTexture;
    GLuint						sonoTexture;
    
    
    
    aurioTouchDisplayMode		displayMode;
    
//    BOOL						mute;
    
    BOOL                        interruption;
    
    SpectrumLinkedTexture*		firstTex;
    FFTBufferManager*			fftBufferManager;
    DCRejectionFilter*			dcFilter;
    CAStreamBasicDescription	thruFormat;
    CAStreamBasicDescription    drawFormat;
    AudioBufferList*            drawABL;
    Float64						hwSampleRate;
    
    AudioConverterRef           audioConverter;
    
    UIEvent*					pinchEvent;
    CGFloat						lastPinchDist;
    
    AURenderCallbackStruct		inputProc;
    
    SystemSoundID				buttonPressSound;
    
    int32_t*					l_fftData;
    
    GLfloat*					oscilLine;
    BOOL						resetOscilLine;
    
    BOOL                        _isListenning;
}

@end

@implementation AppDelegate

GLfloat colorLevels[] = {
    0., 1., 0., 0., 0.,
    .333, 1., .7, 0., 0.,
    .667, 1., 0., 0., 1.,
    1., 1., 0., 1., 1.,
};

@synthesize window;
@synthesize view;

@synthesize rioUnit;
@synthesize unitIsRunning;
@synthesize unitHasBeenCreated;
//@synthesize displayMode;
//@synthesize fftBufferManager;
@synthesize mute;
@synthesize inputProc;
@synthesize interruption;

#pragma mark-

CGPathRef CreateRoundedRectPath(CGRect RECT, CGFloat cornerRadius)
{
    CGMutablePathRef		path;
    path = CGPathCreateMutable();
    
    double		maxRad = MAX(CGRectGetHeight(RECT) / 2., CGRectGetWidth(RECT) / 2.);
    
    if (cornerRadius > maxRad) cornerRadius = maxRad;
    
    CGPoint		bl, tl, tr, br;
    
    bl = tl = tr = br = RECT.origin;
    tl.y += RECT.size.height;
    tr.y += RECT.size.height;
    tr.x += RECT.size.width;
    br.x += RECT.size.width;
    
    CGPathMoveToPoint(path, NULL, bl.x + cornerRadius, bl.y);
    CGPathAddArcToPoint(path, NULL, bl.x, bl.y, bl.x, bl.y + cornerRadius, cornerRadius);
    CGPathAddLineToPoint(path, NULL, tl.x, tl.y - cornerRadius);
    CGPathAddArcToPoint(path, NULL, tl.x, tl.y, tl.x + cornerRadius, tl.y, cornerRadius);
    CGPathAddLineToPoint(path, NULL, tr.x - cornerRadius, tr.y);
    CGPathAddArcToPoint(path, NULL, tr.x, tr.y, tr.x, tr.y - cornerRadius, cornerRadius);
    CGPathAddLineToPoint(path, NULL, br.x, br.y + cornerRadius);
    CGPathAddArcToPoint(path, NULL, br.x, br.y, br.x - cornerRadius, br.y, cornerRadius);
    
    CGPathCloseSubpath(path);
    
    CGPathRef				ret;
    ret = CGPathCreateCopy(path);
    CGPathRelease(path);
    return ret;
}
void cycleOscilloscopeLines()
{
    // Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
    int drawBuffer_i;
    for (drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
        memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], drawBufferLen);
}
#pragma mark -Audio Session Interruption Listener
void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
    try {
        printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
        
        AppDelegate *THIS = (AppDelegate *)CFBridgingRelease(inClientData);
        
        if (inInterruption == kAudioSessionEndInterruption) {
            // make sure we are again the active session
            XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active");
            XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
            
            THIS->interruption = NO;
        }
        
        if (inInterruption == kAudioSessionBeginInterruption) {
            
            THIS->interruption = YES;
            
            XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}
#pragma mark -Audio Session Property Listener

void propListener(	void *                  inClientData,
                  AudioSessionPropertyID	inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
    AppDelegate *THIS = (__bridge AppDelegate*)inClientData;
    if (inID == kAudioSessionProperty_AudioRouteChange)
    {
        try {
            UInt32 isAudioInputAvailable;
            UInt32 size = sizeof(isAudioInputAvailable);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isAudioInputAvailable), "couldn't get AudioSession AudioInputAvailable property value");
            
            if(THIS->unitIsRunning && !isAudioInputAvailable)
            {
                XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
                THIS->unitIsRunning = false;
            }
            
            else if(!THIS->unitIsRunning && isAudioInputAvailable)
            {
                XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
                
                if (!THIS->unitHasBeenCreated)	// the rio unit is being created for the first time
                {
                    XThrowIfError(SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat), "couldn't setup remote i/o unit");
                    THIS->unitHasBeenCreated = true;
                    
                    THIS->dcFilter = new DCRejectionFilter[THIS->thruFormat.NumberChannels()];
                    
                    UInt32 maxFPS;
                    size = sizeof(maxFPS);
                    XThrowIfError(AudioUnitGetProperty(THIS->rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
                    
                    THIS->fftBufferManager = new FFTBufferManager(maxFPS);
                    THIS->l_fftData = new int32_t[maxFPS/2];
                    
                    THIS->oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
                }
                
                XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
                THIS->unitIsRunning = true;
            }
            
            // we need to rescale the sonogram view's color thresholds for different input
            CFStringRef newRoute;
            size = sizeof(CFStringRef);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute), "couldn't get new audio route");
            if (newRoute)
            {
                CFShow(newRoute);
                if (CFStringCompare(newRoute, CFSTR("Headset"), NULL) == kCFCompareEqualTo) // headset plugged in
                {
                    colorLevels[0] = .3;
                    colorLevels[5] = .5;
                }
                else if (CFStringCompare(newRoute, CFSTR("Receiver"), NULL) == kCFCompareEqualTo) // headset plugged in
                {
                    colorLevels[0] = 0;
                    colorLevels[5] = .333;
                    colorLevels[10] = .667;
                    colorLevels[15] = 1.0;
                    
                }
                else
                {
                    colorLevels[0] = 0;
                    colorLevels[5] = .333;
                    colorLevels[10] = .667;
                    colorLevels[15] = 1.0;
                    
                }
            }
        } catch (CAXException e) {
            char buf[256];
            fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        }
        
    }
}
#pragma mark -RIO Render Callback

static OSStatus	PerformThru(
                            void						*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp 		*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList 			*ioData)
{
    AppDelegate *THIS = (AppDelegate *)CFBridgingRelease(inRefCon);
    OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
    
    // Remove DC component
    for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
        THIS->dcFilter[i].InplaceFilter((Float32*)(ioData->mBuffers[i].mData), inNumberFrames);
    
    if (THIS->displayMode == aurioTouchDisplayModeOscilloscopeWaveform)
    {
        // The draw buffer is used to hold a copy of the most recent PCM data to be drawn on the oscilloscope
        if (drawBufferLen != drawBufferLen_alloced)
        {
            int drawBuffer_i;
            
            // Allocate our draw buffer if needed
            if (drawBufferLen_alloced == 0)
                for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
                    drawBuffers[drawBuffer_i] = NULL;
            
            // Fill the first element in the draw buffer with PCM data
            for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
            {
                drawBuffers[drawBuffer_i] = (SInt8 *)realloc(drawBuffers[drawBuffer_i], drawBufferLen);
                bzero(drawBuffers[drawBuffer_i], drawBufferLen);
            }
            
            drawBufferLen_alloced = drawBufferLen;
        }
        
        int i;
        
        //Convert the floating point audio data to integer (Q7.24)
        err = AudioConverterConvertComplexBuffer(THIS->audioConverter, inNumberFrames, ioData, THIS->drawABL);
        if (err) { printf("AudioConverterConvertComplexBuffer: error %d\n", (int)err); return err; }
        
        SInt8 *data_ptr = (SInt8 *)(THIS->drawABL->mBuffers[0].mData);
        for (i=0; i<inNumberFrames; i++)
        {
            if ((i+drawBufferIdx) >= drawBufferLen)
            {
                cycleOscilloscopeLines();
                drawBufferIdx = -i;
            }
            drawBuffers[0][i + drawBufferIdx] = data_ptr[2];
            data_ptr += 4;
        }
        drawBufferIdx += inNumberFrames;
        
        if (THIS->fftBufferManager == NULL) return noErr;
        
        if (THIS->fftBufferManager->NeedsNewAudioData())
            THIS->fftBufferManager->GrabAudioData(ioData);
    }
    
    else if ((THIS->displayMode == aurioTouchDisplayModeSpectrum) || (THIS->displayMode == aurioTouchDisplayModeOscilloscopeFFT))
    {
        if (THIS->fftBufferManager == NULL) return noErr;
        
        if (THIS->fftBufferManager->NeedsNewAudioData())
            THIS->fftBufferManager->GrabAudioData(ioData); 
    }
    if (THIS->mute == YES) { SilenceData(ioData); }
    
    return err;
}
#pragma mark-

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
    
      //self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
      
      //self.view.backgroundColor = [UIColor whiteColor];
    /**************************波形****************************************/
      [self __applicationDidFinishLaunching:application];
    /***********************************************************************/
      //[self.window makeKeyAndVisible];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    /****************************/
    view.applicationResignedActive = YES;
    [view stopAnimation];
    /*****************************/

}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    /************************************/
    view.applicationResignedActive = NO;
    [view startAnimation];
    AudioSessionSetActive(true);
    AudioOutputUnitStart(self.rioUnit);
    /************************************/

}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self saveContext];

}

- (void)__applicationDidFinishLaunching:(UIApplication *)application
{
    //    self.view = [[[EAGLView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 64.0)] autorelease];
    self.view = [[[EAGLView alloc] initWithFrame:CGRectMake(0.0,0.0,450.0,64.0)] autorelease];/*************1111111111************/
    //    RootViewController *rootViewController = [[[RootViewController alloc] init] autorelease];
    //    self.window.rootViewController = rootViewController;
    //    [rootViewController.view setBackgroundColor:[UIColor clearColor]];
    //    [rootViewController.view addSubview:self.view];
    
    //   MainViewController *mMainViewController = [[[MainViewController alloc] init] autorelease];
    //   self.window.rootViewController = mMainViewController;
    
    // ViewController * ctrlr = [[[ViewController alloc] init] autorelease];
    // self.window.rootViewController = ctrlr;
    /*******************/
    //[ctrlr.view setBackgroundColor:[UIColor clearColor]];
    //[ctrlr.view addSubview:self.view];
    
    _isListenning = YES;
    
#ifdef __IPHONE_8_0
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            
            if (!granted) {
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"没有开启麦克风" message:@"请到[设置]->[隐私]->[麦克风]中开启" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];// autorelease];
                [alertView show];
            }
            
        }];
    }
#endif
    
    // Turn off the idle timer, since this app doesn't rely on constant touch input
    application.idleTimerDisabled = YES;
    
    // mute should be on at launch
    self.mute = TRUE;
    displayMode = aurioTouchDisplayModeOscilloscopeWaveform;
    
    // Initialize our remote i/o unit
    
    inputProc.inputProc = PerformThru;
    inputProc.inputProcRefCon = self;
    
    
    
    ////////
    [self setupListening];
    ////////
    
    
    
    // Set ourself as the delegate for the EAGLView so that we get drawing and touch events
    view.delegate = self;
    
    // Enable multi touch so we can handle pinch and zoom in the oscilloscope
    view.multipleTouchEnabled = YES;
    
    
    // Set up our overlay view that pops up when we are pinching/zooming the oscilloscope
    /*
    UIImage *img_ui = nil;
    {
        
        // Draw the rounded rect for the bg path using this convenience function
        CGPathRef bgPath = CreateRoundedRectPath(CGRectMake(0, 0, 110, 234), 15.);
        
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        // Create the bitmap context into which we will draw
        
        CGContextRef cxt = CGBitmapContextCreate(NULL, 110, 234, 8, 4*110, cs, kCGImageAlphaPremultipliedLast);
        CGContextSetFillColorSpace(cxt, cs);
        CGFloat fillClr[] = {0., 0., 0., 0.7};
        CGContextSetFillColor(cxt, fillClr);
        // Add the rounded rect to the context...
        CGContextAddPath(cxt, bgPath);
        // ... and fill it.
        CGContextFillPath(cxt);
        
        // Make a CGImage out of the context
        CGImageRef img_cg = CGBitmapContextCreateImage(cxt);
        // Make a UIImage out of the CGImage
        img_ui = [UIImage imageWithCGImage:img_cg];
        
        // Clean up
        CGImageRelease(img_cg);
        CGColorSpaceRelease(cs);
        CGContextRelease(cxt);
        CGPathRelease(bgPath);
        
    }

    // Create the image view to hold the background rounded rect which we just drew
    sampleSizeOverlay = [[UIImageView alloc] initWithImage:img_ui];
    sampleSizeOverlay.frame = CGRectMake(190, 124, 110, 234);
    
    // Create the text view which shows the size of our oscilloscope window as we pinch/zoom
    sampleSizeText = [[UILabel alloc] initWithFrame:CGRectMake(-62, 0, 234, 234)];
    sampleSizeText.textAlignment = NSTextAlignmentCenter;
    sampleSizeText.textColor = [UIColor whiteColor];
    sampleSizeText.text = @"0000 ms";
    sampleSizeText.font = [UIFont boldSystemFontOfSize:36.];
    // Rotate the text view since we want the text to draw top to bottom (when the device is oriented vertically)
    sampleSizeText.transform = CGAffineTransformMakeRotation(M_PI_2);
    sampleSizeText.backgroundColor = [UIColor clearColor];
    
    // Add the text view as a subview of the overlay BG
    [sampleSizeOverlay addSubview:sampleSizeText];
    // Text view was retained by the above line, so we can release it now
    //    [sampleSizeText release];
    
    // We don't add sampleSizeOverlay to our main view yet. We just hang on to it for now, and add it when we
    // need to display it, i.e. when a user starts a pinch/zoom.
 
    // Set up the view to refresh at 20 hz
    [view setAnimationInterval:1./20.];
    [view startAnimation];
    
    */
    
    
    /**************************/
}
- (void)setupListening{
    
    
    CFURLRef url = NULL;
    try {
        //		url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFStringRef([[NSBundle mainBundle] pathForResource:@"button_press" ofType:@"caf"]), kCFURLPOSIXPathStyle, false);
        //		XThrowIfError(AudioServicesCreateSystemSoundID(url, &buttonPressSound), "couldn't create button tap alert sound");
        //		CFRelease(url);
        
        // Initialize and configure the audio session
        XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");
        self.interruption = NO;
        UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
        XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
        XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self), "couldn't set property listener");
        
        //Float32 preferredBufferSize = .0872;
        Float32 preferredBufferSize = .0873;
        
        XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
        
        UInt32 size = sizeof(hwSampleRate);
        XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
        
        XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
        XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
        unitHasBeenCreated = true;
        
        drawFormat.SetAUCanonical(2, false);
        drawFormat.mSampleRate = 44100;
        
        XThrowIfError(AudioConverterNew(&thruFormat, &drawFormat, &audioConverter), "couldn't setup AudioConverter");
        
        dcFilter = new DCRejectionFilter[thruFormat.NumberChannels()];
        
        UInt32 maxFPS;
        size = sizeof(maxFPS);
        XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
        
        fftBufferManager = new FFTBufferManager(maxFPS);
        l_fftData = new int32_t[maxFPS/2];
        
        drawABL = (AudioBufferList*) malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
        drawABL->mNumberBuffers = 2;
        for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
        {
            drawABL->mBuffers[i].mData = (SInt32*) calloc(maxFPS, sizeof(SInt32));
            drawABL->mBuffers[i].mDataByteSize = maxFPS * sizeof(SInt32);
            drawABL->mBuffers[i].mNumberChannels = 1;
        }
        
        oscilLine = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
        
        XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
        size = sizeof(thruFormat);
        XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
        
        unitIsRunning = 1;
    }
    catch (CAXException &e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        unitIsRunning = 0;
        if (dcFilter) delete[] dcFilter;
        if (drawABL)
        {
            for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
                free(drawABL->mBuffers[i].mData);
            free(drawABL);
            drawABL = NULL;
        }
        if (url) CFRelease(url);
    }
    catch (...) {
        fprintf(stderr, "An unknown error occurred\n");
        unitIsRunning = 0;
        if (dcFilter) delete[] dcFilter;
        if (drawABL)
        {
            for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
                free(drawABL->mBuffers[i].mData);
            free(drawABL);
            drawABL = NULL;
        }
        if (url) CFRelease(url);
    }
}


- (void)createGLTexture:(GLuint *)texName fromCGImage:(CGImageRef)img
{
    /*****************************************************************************************************/
    
    GLubyte *spriteData = NULL;
    CGContextRef spriteContext;
    GLuint imgW, imgH, texW, texH;
    
    imgW = CGImageGetWidth(img);
    imgH = CGImageGetHeight(img);
    
    // Find smallest possible powers of 2 for our texture dimensions
    for (texW = 1; texW < imgW; texW *= 2) ;
    for (texH = 1; texH < imgH; texH *= 2) ;
    
    // Allocated memory needed for the bitmap context
    spriteData = (GLubyte *) calloc(texH, texW * 4);
    // Uses the bitmatp creation function provided by the Core Graphics framework.
    spriteContext = CGBitmapContextCreate(spriteData, texW, texH, 8, texW * 4, CGImageGetColorSpace(img),
                                          kCGImageAlphaPremultipliedLast);
    //kCGImageAlphaPremultipliedLast);
    
    
    // Translate and scale the context to draw the image upside-down (conflict in flipped-ness between GL textures and CG contexts)
    CGContextTranslateCTM(spriteContext, 0., texH);
    CGContextScaleCTM(spriteContext, 1., -1.);
    
    // After you create the context, you can draw the sprite image to the context.
    CGContextDrawImage(spriteContext, CGRectMake(0.0, 0.0, imgW, imgH), img);
    // You don't need the context at this point, so you need to release it to avoid memory leaks.
    CGContextRelease(spriteContext);
    
    // Use OpenGL ES to generate a name for the texture.
    glGenTextures(1, texName);
    // Bind the texture name.
    glBindTexture(GL_TEXTURE_2D, *texName);
    // Speidfy a 2D texture image, provideing the a pointer to the image data in memory
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texW, texH, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    // Enable use of the texture
    glEnable(GL_TEXTURE_2D);
    // Set a blending function to use
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    // Enable blending
    glEnable(GL_BLEND);
    
    free(spriteData);
    
}

- (void)setupViewForOscilloscope
{
    // 下面这些图被删了，所以log会报一堆错
    
    
    CGImageRef img;                                     /********************/
    
    // Load our GL textures
   
    img = [UIImage imageNamed:@"top.png"].CGImage;
    [self createGLTexture:&bgTexture fromCGImage:img];
    
    /*
     img = [UIImage imageNamed:@"fft_off.png"].CGImage;
     [self createGLTexture:&fftOffTexture fromCGImage:img];
     
     img = [UIImage imageNamed:@"fft_on.png"].CGImage;
     [self createGLTexture:&fftOnTexture fromCGImage:img];
     
     img = [UIImage imageNamed:@"mute_off.png"].CGImage;
     [self createGLTexture:&muteOffTexture fromCGImage:img];
     
     img = [UIImage imageNamed:@"mute_on.png"].CGImage;
     [self createGLTexture:&muteOnTexture fromCGImage:img];
     
     img = [UIImage imageNamed:@"sonogram.png"].CGImage;
     [self createGLTexture:&sonoTexture fromCGImage:img];
     */
    
    initted_oscilloscope = YES;
}
- (void)dealloc
{
    delete[] dcFilter;
    delete fftBufferManager;
    if (drawABL)
    {
        for (UInt32 i=0; i<drawABL->mNumberBuffers; ++i)
            free(drawABL->mBuffers[i].mData);
        free(drawABL);
        drawABL = NULL;
    }
    [view release];
    [window release];
    
    free(oscilLine);
    
    //   _getWaveTransMetadataDelegate = nil;
    
    [super dealloc];
}


- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH
{
    if (LENGTH != fftLength)
    {
        fftLength = LENGTH;
        fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
    }
    memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
    hasNewFFTData = YES;
}


static queue   _savedBuffer[32];
//static int     _indexBufferX;

- (void)setupQueue {
    
    static BOOL flag = NO;
    
    if (!flag) {
        
        for (int i=0; i<32; i++) {
            
            queue q;
            _savedBuffer[i] = q;
            init_queue(&_savedBuffer[i], 20);
        }
        
        flag = YES;
    }
}


- (void)helper:(double)fftIdx_i interpVal:(CGFloat)interpVal timeSlice:(int)length {
    
    [self setupQueue];
    
    float fff = (drawFormat.mSampleRate / 2.0) * (int)fftIdx_i / (fftLength);
    
    int code = -1;
    
    if (freq_to_num(fff, &code) == 0 && code >= 0 && code < 32) {
        
        //enqueue_adv(&_savedBuffer[code], interpVal);
        
        enqueue(&_savedBuffer[code], interpVal);
        
        //NSLog(@"%d", code);
    }
}
- (void)helperResultWithTimeSlice:(int)length {
    
    queue *q17 = &_savedBuffer[17];
    queue *q19 = &_savedBuffer[19];
    
    if (queue_item_at_index(q17, 0) > 0.0 &&
        queue_item_at_index(q17, 1) > 0.0 &&
        queue_item_at_index(q19, 1) > 0.0 &&
        queue_item_at_index(q19, 2) > 0.0) {
        
        
        float minValue = fmin(queue_item_at_index(q17, 2), queue_item_at_index(q19, 3));
        minValue = fmax(minValue, queue_item_at_index(q17, 0) * 0.7);
        
        //        float minValue_17 = fmin(queue_item_at_index(q17, 0), queue_item_at_index(q17, 1));
        //        float minValue_19 = fmin(queue_item_at_index(q19, 1), queue_item_at_index(q19, 2));
        //
        //        minValue = fmin(minValue_17,minValue_19) * 0.75;
        
        
        float maxValue = fmax(queue_item_at_index(q17, 0), queue_item_at_index(q19, 1)) * 1.85;
        
        //        minValue = 0.0;
        //        maxValue = 1.0;
        
        
        int res[20];
        int rrr[20];
        generate_data(_savedBuffer, 32, res, rrr, 20, minValue, maxValue);
        
        /*
         if (res[0] != 17 || res[1] != 19) {
         return;
         }else {
         _isListenning = NO;
         }
         */
        
        printf("\n================= start:(19[0]=%f), (17[2]=%f), (19[3]=%f), (17[0]*0.7=%f), (minValue=%f) ==================\n\n", queue_item_at_index(q19, 0), queue_item_at_index(q17, 2), queue_item_at_index(q19, 3), queue_item_at_index(q17, 0) * 0.7, minValue);
        
        for (int i=0; i<20; i++) {
            printf("%02d ", res[i]);
        }
        
        for (int i=0; i<10; i++) {
            
            int temp;
            
            temp = rrr[i];
            rrr[i] = rrr[19-i];
            rrr[19-i] = temp;
        }
        
        printf("\n");
        
        for (int i=0; i<20; i++) {
            printf("%02d ", rrr[i]);
        }
        
        printf("\n\n");
        
        
        //////////////  RS
        
        int temp[18];
        int result[18][18];
        int counter = 0;
        
        for (int i=0; i<18; i++) {
            for (int j=0; j<18; j++) {
                
                result[i][j] = -1;
            }
        }
        
        for (int k = 2; k < 20; k++) {
            
            printf("~~~~~~~ %02d :17 19 ", k);
            
            for (int i=2, j=0; i<20; i++, j++) {
                
                if (i <= k) {
                    temp[j] = res[i];
                }else {
                    temp[j] = rrr[i];
                }
                
                printf("%02d ", temp[j]);
            }
            
            printf(" ~~~~~~~ ");
            
            RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
            int eras_pos[RS_TOTAL_LEN] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
            
            unsigned char data1[RS_TOTAL_LEN];
            
            for (int i=0; i<RS_TOTAL_LEN; i++) {
                data1[i] = temp[i];
            }
            
            int count = decode_rs_char(rs, data1, eras_pos, 0);
            
            /////////////////
            
            if (count >= 0) {
                
                for (int m = 0; m<18; m++) {
                    
                    result[m][counter] = data1[m];
                }
                
                counter++;
            }
            
            printf("17 19 ");
            for (int i=0; i<18; i++) {
                printf("%02d ", data1[i]);
            }
            printf("    %d\n", count);
        }
        
        int temp_vote[18] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        int final_result[20] = {17, 19, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
        
        for (int i=0; i<18; i++) {
            
            for (int j=0; j<18; j++) {
                
                temp_vote[j] = result[i][j];
            }
            
            vote(temp_vote, 18, &final_result[i+2]);
        }
        
        printf("\n ================== final result ================== \n\n");
        
        //printf("17-19-00-30-19-13-05-22-12-10-02-02-27-00-20-08-09-21-26-29-\n");
        
        if (counter == 0) {
            
            printf("fail!");
            
        }else {
            
            NSMutableString *string = [NSMutableString stringWithFormat:@""];
            
            /*
             
             */
            
            
            for (int i=0; i<20; i++) {
                
                printf("%02d ", final_result[i]);
              
                if (i>=2 && i<=11) {
                    
                    char res_char;
                    num_to_char(final_result[i], &res_char);
                    
                    [string appendFormat:@"%c", res_char];
                }
                
            }
            
            _isListenning = NO;
            
            
            //绑定音频数据到URL
             NSString* path;
             if(   final_result[2]==10  && final_result[3]==18  && final_result[4]==10  && final_result[5]==22
                && final_result[6]==24  && final_result[7]==02  && final_result[8]==20  && final_result[9]== 4
                && final_result[10]==19 && final_result[11]== 8 && final_result[12]== 9 && final_result[13]==27
                && final_result[14]==18 && final_result[15]==10 && final_result[16]==18 && final_result[17]==17
                && final_result[18]==8  && final_result[19]==13){
             //self.window.rootViewController.
                  path = @"http://cv15425558.imwork.net:2501/gsound/buildinfo?id=12345";
             
             }else if(   final_result[2]==13   && final_result[3]==12  && final_result[4]==17   && final_result[5]==18
                      && final_result[6]==2   && final_result[7]==29  && final_result[8]==9  && final_result[9]==11
                      && final_result[10]==17  && final_result[11]==18  && final_result[12]==16 && final_result[13]==25
                      && final_result[14]==13 && final_result[15]==15  && final_result[16]==18 && final_result[17]==16
                      && final_result[18]==28  && final_result[19]==19){
             //self.window.rootViewController
                  path = @"http://cv15425558.imwork.net:2501/gsound/buildinfo?id=54321";
             }/*else{
                  _isListenning = YES;
             }*/
            
             UIViewController * currVC = nil;
             UIViewController * Rootvc = self.window.rootViewController ;
             do {
             if ([Rootvc isKindOfClass:[UINavigationController class]]) {
             UINavigationController * nav = (UINavigationController *)Rootvc;
             UIViewController * v = [nav.viewControllers lastObject];
             currVC = v;
             Rootvc = v.presentedViewController;
             continue;
             }else if([Rootvc isKindOfClass:[UITabBarController class]]){
             UITabBarController * tabVC = (UITabBarController *)Rootvc;
             currVC = tabVC;
             Rootvc = [tabVC.viewControllers objectAtIndex:tabVC.selectedIndex];
             continue;
             }else if ([Rootvc isKindOfClass:[ViewController class]]){
             ViewController * tabVC = (ViewController *)Rootvc;
           //  NSLog(@"+++++++++%@+++++++++++",path);
             [tabVC loadcompany:path];                        //currVC = tabVC;
             //Rootvc = tabVC.selectedViewController;
             NSLog(@"++++++++++gggggggg+++++++++++++");
                 break;
             
             }
             } while (Rootvc!=nil);
             
            

            //请求
            /*
             if (self.getWaveTransMetadataDelegate != nil && [self.getWaveTransMetadataDelegate respondsToSelector:@selector(getWaveTransMetadata:)]) {
             
             WaveTransMetadata *metadata = [[[WaveTransMetadata alloc] initWithDictionary:@{@"code":string}] autorelease];
             
             [self.getWaveTransMetadataDelegate getWaveTransMetadata:metadata];
             
             }else {
             
             _isListenning = YES;
             }*/
        }
        
        /*
         RS *rs = init_rs(RS_SYMSIZE, RS_GFPOLY, RS_FCR, RS_PRIM, RS_NROOTS, RS_PAD);
         int eras_pos[RS_TOTAL_LEN] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
         
         unsigned char data1[RS_TOTAL_LEN];
         
         for (int i=0; i<RS_TOTAL_LEN; i++) {
         data1[i] = res[i+2];
         }
         
         int count = decode_rs_char(rs, data1, eras_pos, 0);
         
         /////////////////
         
         printf("17 19 ");
         for (int i=0; i<18; i++) {
         printf("%02d ", data1[i]);
         }
         printf("    %d\n", count);
         */
        
        /*
         for (int i = 0; i<32; i++) {
         
         for (int k = 0; k<20; k++) {
         
         queue *q = &_savedBuffer[i];
         float currentValue = queue_item_at_index(q, k);
         
         if (currentValue <= minValue || currentValue >= maxValue) {
         
         currentValue = 0.0;
         }
         
         printf("%d,%d,%.4f]", i, k, currentValue);
         }
         }
         */
        
        printf("\n\n================  end  ==================\n");
        _isListenning = YES;
        
        //printf("\n");
    }
}
- (void)computeWave {
    
    if (_isListenning == YES && fftBufferManager->HasNewAudioData()) {
        
        if (fftBufferManager->ComputeFFT(l_fftData)) {
            
            [self setFFTData:l_fftData length:fftBufferManager->GetNumberFrames() / 2];
            
            int i;
            for (i=0; i<32; i++) {
                
                unsigned int freq;
                int fftIdx;
                
                num_to_freq(i, &freq);
                fftIdx = freq / (drawFormat.mSampleRate / 2.0) * fftLength;
                
                double fftIdx_i, fftIdx_f;
                fftIdx_f = modf(fftIdx, &fftIdx_i);
                
                SInt8 fft_l, fft_r;
                CGFloat fft_l_fl, fft_r_fl;
                CGFloat interpVal;
                
                fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
                fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
                fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
                fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
                interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
                
                interpVal = sqrt(CLAMP(0., interpVal, 1.));
                
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                [self helper:fftIdx interpVal:interpVal timeSlice:6];///////////
                //////////////////////////////////////////////////////////////////
                //////////////////////////////////////////////////////////////////
                
            }
            
            //////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////
            [self helperResultWithTimeSlice:6];///////////////////////////////
            //////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////
        }
        else
            hasNewFFTData = NO;
    }
}
- (void)drawOscilloscope
{
    // Clear the view
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    
    glColor4f(1., 1., 1., 1.);
    
    glPushMatrix();
    
    glTranslatef(0., 0., 0.);
    glRotatef(0., 0., 0., 1.);
    
    
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    
    {
        // Draw our background oscilloscope screen
        const GLfloat vertices[] = {
            0., 0.,
            512., 0.,
            0.,  64.,
            512.,  64.,
        };
        const GLshort texCoords[] = {
            0, 0,
            1, 0,
            0, 1,
            1, 1,
        };
        
        
        glBindTexture(GL_TEXTURE_2D, bgTexture);
        
        glVertexPointer(2, GL_FLOAT, 0, vertices);
        glTexCoordPointer(2, GL_SHORT, 0, texCoords);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    /*
     {
     // Draw our buttons
     const GLfloat vertices[] = {
     0., 0.,
     112, 0.,
     0.,  64,
     112,  64,
     };
     const GLshort texCoords[] = {
     0, 0,
     1, 0,
     0, 1,
     1, 1,
     };
     
     glPushMatrix();
     
     glVertexPointer(2, GL_FLOAT, 0, vertices);
     glTexCoordPointer(2, GL_SHORT, 0, texCoords);
     
     glTranslatef(5, 0, 0);
     glBindTexture(GL_TEXTURE_2D, sonoTexture);
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     glTranslatef(99, 0, 0);
     glBindTexture(GL_TEXTURE_2D, mute ? muteOnTexture : muteOffTexture);
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     glTranslatef(99, 0, 0);
     glBindTexture(GL_TEXTURE_2D, (displayMode == aurioTouchDisplayModeOscilloscopeFFT) ? fftOnTexture : fftOffTexture);
     glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     
     glPopMatrix();
     
     }
     */
    
    
    //	if (displayMode == aurioTouchDisplayModeOscilloscopeFFT)
    //	{
    
    
    //		if (hasNewFFTData)
    //		{
    //
    //			int y, maxY;
    //			maxY = drawBufferLen;
    //			for (y=0; y<maxY; y++)
    //			{
    //				CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
    //				CGFloat fftIdx = yFract * ((CGFloat)fftLength);
    //
    //				double fftIdx_i, fftIdx_f;
    //				fftIdx_f = modf(fftIdx, &fftIdx_i);
    //
    //				SInt8 fft_l, fft_r;
    //				CGFloat fft_l_fl, fft_r_fl;
    //				CGFloat interpVal;
    //
    //				fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
    //				fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
    //				fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
    //				fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
    //				interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
    //
    //				interpVal = CLAMP(0., interpVal, 1.);
    //
    //				drawBuffers[0][y] = (interpVal * 120);
    //
    //			}
    //			cycleOscilloscopeLines();
    //
    //		}
    //
    //	}
    
    
    [self computeWave];/****************/
    
    
    GLfloat *oscilLine_ptr;
    GLfloat max = drawBufferLen / 4 * self.view.frame.size.width / 450;
    SInt8 *drawBuffer_ptr;
    
    // Alloc an array for our oscilloscope line vertices
    if (resetOscilLine) {
        oscilLine = (GLfloat*)realloc(oscilLine, drawBufferLen * 2 * sizeof(GLfloat) / 4 * self.view.frame.size.width / 450);
        resetOscilLine = NO;
    }
    
    glPushMatrix();
    
    // Translate to the left side and vertical center of the screen, and scale so that the screen coordinates
    // go from 0 to 1 along the X, and -1 to 1 along the Y
    glTranslatef(0., self.view.frame.size.height / 2.0, 0.);
    //glScalef(self.view.frame.size.width - 48., self.view.frame.size.height, 1.);
    glScalef(self.view.frame.size.width - 88., self.view.frame.size.height, 1.);
    
    // Set up some GL state for our oscilloscope lines
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisable(GL_LINE_SMOOTH);
    glLineWidth(2.);
    
    int drawBuffer_i;
    // Draw a line for each stored line in our buffer (the lines are stored and fade over time)
    for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
    {
        if (!drawBuffers[drawBuffer_i]) continue;
        
        oscilLine_ptr = oscilLine;
        drawBuffer_ptr = drawBuffers[drawBuffer_i];
        
        GLfloat i;
        // Fill our vertex array with points
        for (i=0.; i<max; i=i+1.)
        {
            *oscilLine_ptr++ = i/max;
            
            /*
             if (abs((int)(*drawBuffer_ptr)) < self.view.frame.size.height / 3.0) {
             
             *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 64.;
             
             } else {
             
             *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 256.;
             }
             */
            
            *oscilLine_ptr++ = (Float32)(*drawBuffer_ptr) / 128.;
            //NSLog(@"%f", (Float32)(*drawBuffer_ptr));
            
            drawBuffer_ptr += 4;
        }
        
        // If we're drawing the newest line, draw it in solid green. Otherwise, draw it in a faded green.
        
        if ([PCMRender isHighFreq]) {
            
            if (drawBuffer_i == 0)
                glColor4f(1., 0., 0., 1.);
            else
                glColor4f(1., 0., 0., (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
            
        } else {
            
            if (drawBuffer_i == 0)
                glColor4f(.8, .8, .8, 1.);
            else
                glColor4f(.8, .8, .8, (.24 * (1. - ((GLfloat)drawBuffer_i / (GLfloat)kNumDrawBuffers))));
        }
        
        
        
        // Set up vertex pointer,
        glVertexPointer(2, GL_FLOAT, 0, oscilLine);
        
        // and draw the line.
        glDrawArrays(GL_LINE_STRIP, 0, drawBufferLen / 4 * self.view.frame.size.width / 450);
        
    }
    
    glPopMatrix();
    
    glPopMatrix();
}

- (void)drawView:(id)sender forTime:(NSTimeInterval)time
{
    if ((displayMode == aurioTouchDisplayModeOscilloscopeWaveform) || (displayMode == aurioTouchDisplayModeOscilloscopeFFT))
    {
        if (!initted_oscilloscope) [self setupViewForOscilloscope];
        [self drawOscilloscope];            //////////////////////////////////////画频谱
    } /*else if (displayMode == aurioTouchDisplayModeSpectrum) {
       if (!initted_spectrum) [self setupViewForSpectrum];
       [self drawSpectrum];
       }*/
}


+ (AppDelegate *)sharedAppDelegate {
    
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}
- (void)setListenning:(BOOL)state {
    
    _isListenning = state;
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"__"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}
#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}


@end
