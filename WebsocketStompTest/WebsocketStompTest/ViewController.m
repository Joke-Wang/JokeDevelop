//
//  ViewController.m
//  WebsocketStompTest
//
//  Created by 王章仲 on 2018/12/3.
//  Copyright © 2018 王章仲. All rights reserved.
//

#import "ViewController.h"
#import <WebsocketStompKit/WebsocketStompKit.h>

@interface ViewController ()<STOMPClientDelegate>
@property (nonatomic, strong) STOMPClient *client;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    [self logStatus];
}
- (IBAction)connectStompSocket:(UIButton *)sender {
    
    NSString *str = @"";
    //    str = @"http://10.0.10.11:9320/test/bullet";
    //    str = @"ws://bitbang.coinpost.us/bmtSocket/marketV2";
    //    str = @"ws://bitbang.coinpost.us/bmtSocket/websocket";
    //    str = @"ws://10.0.10.11:7397/ws";
    str = @"ws://47.74.235.101:8180/ws-stomp";
    
    NSURL *webSocketUrl = [NSURL URLWithString:str];
    
    self.client = [[STOMPClient alloc] initWithURL:webSocketUrl webSocketHeaders:nil useHeartbeat:YES];
    
    self.client.delegate = self;
    
    [self.client connectWithHeaders:nil
           completionHandler:^(STOMPFrame *connectedFrame, NSError *error)
    {
        NSLog(@"\n-- 5 --\n%@", connectedFrame);
        
//        [self.client sendTo:@"" body:jsonString];
        
        NSArray *arr = @[@"/exchange/market/OKEX.BTC.*"];
        
        for (NSString *item in arr) {
            [self.client subscribeTo:item
                      messageHandler:^(STOMPMessage *message)
             {
                 NSLog(@"body = %@",message.body);
             }];
        }
    }];
    
}

- (IBAction)stopStompSocket:(UIButton *)sender {
    [self.client disconnect];
}

- (void)websocketDidDisconnect:(NSError *)error {
    NSLog(@"%@", error);
    
//    [self connectStompSocket:nil];
}




// MARK: - Socket
- (IBAction)connectSocket:(UIButton *)sender {
    
}

- (IBAction)stopSocket:(UIButton *)sender {
    
}




@end
