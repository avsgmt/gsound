//
//  companycell.m
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import "companycell.h"
#import "companylist.h"
#import "UIImageView+WebCache.h"
@implementation companycell

+(id)COMPANYCELL
{
    return [[NSBundle mainBundle]loadNibNamed:@"companycell" owner:nil options:nil][0];
}
-(void)setCompany:(companylist *)company
{
    _company=company;
    _namelabel.text=company.Cname;
    _addresslabel.text=company.Caddress;
    _websitelabel.text=company.Cwebsite;
    _phonenumlabel.text=company.Cphonenum;
    [self.iconview sd_setImageWithURL:[NSURL URLWithString:company.Cicon]];
     NSLog(@"++++++++++%d+++++++++++++",company.Cicon);
}
-(IBAction)dialnumber:(id)sender
{
    NSString *url=[NSString stringWithFormat:@"tel:%@",_phonenumlabel.text];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:url]];
}
@end
