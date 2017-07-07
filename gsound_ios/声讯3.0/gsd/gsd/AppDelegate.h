//
//  AppDelegate.h
//  gsd
//
//  Created by wanli on 17/5/29.
//  Copyright © 2017年 gmt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>
#import "EAGLView.h"
#import <CoreData/CoreData.h>
//#include <CoreFoundation/CFURL.h>
//#import "FFTBufferManager.h"
//#import "aurio_helper.h"
//#import "CAStreamBasicDescription.h"

//#import "queue.h"
#define SPECTRUM_BAR_WIDTH 4

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif


@interface AppDelegate : UIResponder <UIApplicationDelegate, EAGLViewDelegate>

@property (strong, nonatomic) UIWindow                  *window;
@property (nonatomic, retain)	EAGLView*				view;
@property (nonatomic, assign)	AudioUnit				rioUnit;
@property (nonatomic, assign)	AURenderCallbackStruct	inputProc;
@property (nonatomic, assign)   BOOL                    interruption;
@property (nonatomic, assign)   BOOL                    mute;
@property (nonatomic, assign)	BOOL					unitIsRunning;
@property (nonatomic, assign)	BOOL					unitHasBeenCreated;
@property (readonly, strong)    NSPersistentContainer   *persistentContainer;

- (void)saveContext;
+ (AppDelegate *)sharedAppDelegate;
- (void)setupListenning:(BOOL)state;
@end

