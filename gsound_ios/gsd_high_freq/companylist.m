//
//  companylist.m
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import "companylist.h"

@implementation companylist

-(id)initWithDict:(NSDictionary *)dict
{
    if(self=[super init])
       {
           self.Cname=dict[@"name"];
           self.Caddress=dict[@"address"];
           self.Cphonenum=dict[@"tel"];
           self.Cicon=dict[@"logo"];
           self.Cwebsite=dict[@"webset"];
           NSLog(@"%@",self.Cname);
       }
    return self;
}
+(id)companywithDict:(NSDictionary *)dict
{
    return [[self alloc] initWithDict:dict];
}
@end
