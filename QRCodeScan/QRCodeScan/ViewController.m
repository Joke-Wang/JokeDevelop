//
//  ViewController.m
//  QRCodeScan
//
//  Created by 王章仲 on 2018/11/26.
//  Copyright © 2018 王章仲. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeScanViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}

- (IBAction)jumpScan:(UIButton *)sender {
    QRCodeScanViewController *pushVC = [[QRCodeScanViewController alloc] init];
    pushVC.hidesBottomBarWhenPushed = true;
    [self.navigationController pushViewController:pushVC animated:true];
}

@end
