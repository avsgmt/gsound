//
//  ViewController.m
//  gsd
//
//  Created by wanli on 17/5/29.
//  Copyright © 2017年 gmt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import "AppDelegate.h"
#import "companylist.h"
#import "companycell.h"



/********/


//#import <AVFoundation/AVFoundation.h>
#import "PCMRender.h"
#import "bb_freq_util.h"
//#include "bb_header.h"
//#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/message.h>
//#import "CAXException.h"
#import <AudioToolbox/AudioToolbox.h>
//#import <AddressBook/AddressBook.h>
//#import <AddressBookUI/AddressBookUI.h>





/***********************************/


@interface UIActionSheet (userinfo)

@property (nonatomic, strong) NSDictionary *userinfo;

@end

@implementation UIActionSheet (userinfo)

static char actionSheetUserinfoKey;

- (NSDictionary *)userinfo {
    
    return objc_getAssociatedObject(self, &actionSheetUserinfoKey);
}

- (void)setUserinfo:(NSDictionary *)userinfo {
    
   objc_setAssociatedObject(self, &actionSheetUserinfoKey, userinfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
/******************************************************************///

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate, UIActionSheetDelegate>
@property (nonatomic,strong)NSMutableArray *_allcompanys;
@property (nonatomic,strong) UILabel *freqStatusLabel;
@property (nonatomic,strong) UIAlertView *alert ;

@end

@implementation ViewController

@synthesize freqStatusLabel = _freqStatusLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
   
/**************************************************/
    [self.view addSubview:[AppDelegate sharedAppDelegate].view];
/*************************************************/
    
    //dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   // double delay = 0; // 延迟多少秒
  //  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), queue, ^{
        // 3秒后需要执行的任务
        //  if (TRUE) {
    self._allcompanys=[NSMutableArray array];
    //    [self loadcompany];
    double delayInSeconds = 0.8;
     //   dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
     //       _showCnumber.text=[NSString stringWithFormat:@"共计%lu个单位",(unsigned long)self._allcompanys.count];
     //   });
        //  }
  //  });
    /******************超声***************************/
  
    
    //UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //[addButton setImage:[UIImage imageNamed:@"sent_btn"] forState:UIControlStateNormal];
    //[addButton setShowsTouchWhenHighlighted:YES];
    //[addButton setExclusiveTouch:YES];
    //addButton.backgroundColor = [UIColor redColor];
    //[addButton setFrame:CGRectMake(320-50, 20.0, 40, 40)];
    //addButton.titleLabel.text = @"添加";
    //[addButton addTarget:self action:@selector(openAlbum) forControlEvents:UIControlEventTouchUpInside];
    //[self.view addSubview:addButton];
    
  
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [settingButton setImage:[UIImage imageNamed:@"setting_btn"] forState:UIControlStateNormal];
    [settingButton setShowsTouchWhenHighlighted:YES];
    [settingButton setExclusiveTouch:YES];
    //addButton.backgroundColor = [UIColor redColor];
    [settingButton setFrame:CGRectMake(410-90, 18.0, 40, 40)];
    [settingButton setTitle:@"设置" forState:UIControlStateNormal];
    [settingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [settingButton addTarget:self action:@selector(settingAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:settingButton];
    
    /*
    _freqStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(6., 44., 40., 20.)];
    [_freqStatusLabel setBackgroundColor:[UIColor clearColor]];
    [_freqStatusLabel setFont:[UIFont systemFontOfSize:9.]];
    [_freqStatusLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:_freqStatusLabel];
    
    [self.mTableView setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1.]];
     */
    [self switchToHighFreq:NO];
}


- (void)settingAction {
    
    
    UIActionSheet *chooseImageSheet;
    
    if ([PCMRender isHighFreq]) {
        
        chooseImageSheet = [[UIActionSheet alloc] initWithTitle:@"设置"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"√ 切换为超声模式", @"  切换为低频模式", nil];
        
    } else {
        
        chooseImageSheet = [[UIActionSheet alloc] initWithTitle:@"设置"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"  切换为超声模式", @"√ 切换为低频模式", nil];
    }
    
    
    chooseImageSheet.userinfo = @{@"type" : @"switchFreq"};
    
    [chooseImageSheet showInView:self.view];
    
    [chooseImageSheet release];
}
/*
- (BOOL)isAirPlayActive{
    CFDictionaryRef currentRouteDescriptionDictionary = nil;
    UInt32 dataSize = sizeof(currentRouteDescriptionDictionary);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRouteDescription, &dataSize, &currentRouteDescriptionDictionary);
    if (currentRouteDescriptionDictionary) {
        CFArrayRef outputs = (CFArrayRef)CFDictionaryGetValue(currentRouteDescriptionDictionary, kAudioSession_AudioRouteKey_Outputs);
        if(CFArrayGetCount(outputs) > 0) {
            CFDictionaryRef currentOutput = (CFDictionaryRef)CFArrayGetValueAtIndex(outputs, 0);
            CFStringRef outputType = (CFStringRef)CFDictionaryGetValue(currentOutput, kAudioSession_AudioRouteKey_Type);
            return (CFStringCompare(outputType, kAudioSessionOutputRoute_AirPlay, 0) == kCFCompareEqualTo);
        }
    }
    
    return NO;
}
*/



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}


- (void)switchToHighFreq:(BOOL)isHigh {
    
    int is_high = (isHigh ? 1 : 0);
    
     switch_freq(is_high);
    [PCMRender switchFreq:isHigh];
    
    if (isHigh) {
        
        [_freqStatusLabel setTextColor:[UIColor redColor]];
        _freqStatusLabel.text = @"超声模式";
        
    } else {
        
        [_freqStatusLabel setTextColor:[UIColor whiteColor]];
        _freqStatusLabel.text = @"低频模式";
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.userinfo && [[actionSheet.userinfo objectForKey:@"type"] isEqualToString:@"switchFreq"]) {
        
        switch (buttonIndex) {
            case 0:
            {
                [self switchToHighFreq:YES];
                
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"提示" message:@"您已经切换到超声模式,只能以超声形式接收/发送数据,您也可以使用此模式接收混音广告。(提示:超声人耳是无法感知的)" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
                [alert show];
                //[alert release];
            }
                break;
            case 1:
            {
                
                [self switchToHighFreq:NO];
                
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"提示" message:@"您已经切换到低频模式,只能以低频形式接收/发送数据。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] autorelease];
                [alert show];
                // [alert release];
            }
                break;
            case 2:
            {
                //[[VdiskSession sharedSession] unlink];
                [self performSelector:@selector(linkWeibo) withObject:nil afterDelay:0.1];
            }
                break;
            default:
                break;
        }
        // [super dealloc];
    }
}
- (void)dealloc
{
   
    //delete[] dcFilter;
    //delete fftBufferManager;
   
    //[view release];
    
    free(_alert);

    //[alert release];
    
    [super dealloc];
}



-(void)loadcompany:(NSString *)path{
    
 //   NSString* path  = @"http://cv15425558.imwork.net:2501/gsound/buildinfo?id=";
                    /* @"http://cv15425558.imwork.net:2501/gsound/isakey?mac=7c:46:85:4a:21:8c";*/
    NSURL* url = [NSURL URLWithString:path];
    [self._allcompanys removeAllObjects];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSHTTPURLResponse *httpresponse=(NSHTTPURLResponse *)response;
        if(httpresponse.statusCode==200||httpresponse.statusCode==304){
            NSDictionary *superiordict=[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            for(NSDictionary *inferiordict in [superiordict objectForKey:@"data"]){
                [self._allcompanys addObject:[companylist companywithDict:inferiordict]];
                NSLog(@"%@",self._allcompanys);
            }
            [self.mytable reloadData];
            _showCnumber.text=[NSString stringWithFormat:@"共计%lu个单位",(unsigned long)self._allcompanys.count];
            NSLog(@"++++++++++reloadData+++++++++++++");
        }
    }];
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"%lu",(unsigned long)self._allcompanys.count);
    return self._allcompanys.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Cellid=@"Companyscell";
    companycell *cell=[tableView dequeueReusableCellWithIdentifier:Cellid];
    if(cell==nil)
    {
        cell=[companycell COMPANYCELL];
    }
    companylist *company=self._allcompanys[indexPath.row];
    [cell setCompany:company];
    return cell;
}



@end
