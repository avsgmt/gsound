//
//  ViewController.m
//  声讯
//
//  Created by zhongyangtony on 2017/4/23.
//  Copyright © 2017年 zhongyangtony. All rights reserved.
//

#import "ViewController.h"
#import "companylist.h"
#import "companycell.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong)NSMutableArray *_allcompanys;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self._allcompanys=[NSMutableArray array];
    [self loadcompany];
    double delayInSeconds = 0.8;
    __block ViewController* bself = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    _showCnumber.text=[NSString stringWithFormat:@"共计%lu家企业",(unsigned long)self._allcompanys.count];
    });
}

-(void)loadcompany{
    NSString* path  = @"http://cv15425558.imwork.net:2501/gsound/buildinfo?id=12345";
    NSURL* url = [NSURL URLWithString:path];
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
