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
{
    NSMutableArray *_allcompanys;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *array=[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"companylist.plist" ofType:nil]];
    _allcompanys=[NSMutableArray array];
    for(NSDictionary *dict in array){
        [_allcompanys addObject:[companylist companywithDict:dict]];
    }
    _showCnumber.text=[NSString stringWithFormat:@"共计%lu家企业",(unsigned long)_allcompanys.count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _allcompanys.count;
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
    companylist *company=_allcompanys[indexPath.row];
    cell.company=company;
    return cell;
}

@end
