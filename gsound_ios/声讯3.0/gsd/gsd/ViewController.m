//
//  ViewController.m
//  gsd
//
//  Created by wanli on 17/5/29.
//  Copyright © 2017年 gmt. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "companylist.h"
#import "companycell.h"
/***********************************/
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong)NSMutableArray *_allcompanys;

@end

@implementation ViewController

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
     //       _showCnumber.text=[NSString stringWithFormat:@"共计%lu家企业",(unsigned long)self._allcompanys.count];
     //   });
        //  }
  //  });

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
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
            _showCnumber.text=[NSString stringWithFormat:@"共计%lu家企业",(unsigned long)self._allcompanys.count];
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
