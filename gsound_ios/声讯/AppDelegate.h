//
//  AppDelegate.h
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

