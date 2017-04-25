//
//  companylist.h
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface companylist : NSObject
@property(nonatomic,copy) NSString *Cname;
@property(nonatomic,copy) NSString *Cicon;
@property(nonatomic,copy) NSString *Cphonenum;
@property(nonatomic,copy) NSString *Caddress;
@property(nonatomic,copy) NSString *Cwebsite;
-(id)initWithDict:(NSDictionary *)dict;
+(id)companywithDict:(NSDictionary *)dict;
@end
