//
//  companycell.h
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import <UIKit/UIKit.h>
@class companylist;
@interface companycell : UITableViewCell
@property (nonatomic,weak) IBOutlet UILabel *namelabel;
@property (nonatomic,weak) IBOutlet UILabel *addresslabel;
@property (nonatomic,weak) IBOutlet UILabel *phonenumlabel;
@property (nonatomic,weak) IBOutlet UILabel *websitelabel;
@property (nonatomic,weak) IBOutlet UIImageView *iconview;
-(IBAction)dialnumber:(id)sender;

@property (nonatomic,strong) companylist *company;
+(id)COMPANYCELL;
@end
