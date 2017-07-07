//
//  ViewController.h
//  gsd
//
//  Created by wanli on 17/5/29.
//  Copyright © 2017年 gmt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *showCnumber;
@property (weak,nonatomic) IBOutlet UITableView *mytable;

-(void)loadcompany: (NSString*)path;

@end


