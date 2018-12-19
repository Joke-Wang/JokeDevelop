//
//  BMTSocket.m
//
//  Created by 王章仲 on 2018/1/22.
//

#import "BMTSocket.h"
#import "SRWebSocket.h"
#import "AFNetworking.h"
#import "RealReachability.h"

//判断字符串为空,是赋值为 @""
#define IS_NULL(x)          (!x || [x isKindOfClass:[NSNull class]])
#define IS_EMPTY_STRING(x)  (IS_NULL(x) || [x isEqual:@""] || [x isEqual:@"(null)"])
#define DEFUSE_EMPTY_STRING(x)     (!IS_EMPTY_STRING(x) ? x : @"")

@interface BMTSocket ()<SRWebSocketDelegate>

@property (nonatomic, assign, readwrite) BOOL connected;

@property (nonatomic, assign, readwrite) BOOL closeSocketFoUser;

// 计时器
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) id heartbeatData;
//重连定时器
@property (nonatomic, strong) NSTimer *reconnectionTimer;
@end

@implementation BMTSocket

- (instancetype)init
{
    self = [super init];
    if (self) {
        /// 开启实时监听
        [self listenNetWorkingStatus];
        self.closeSocketFoUser = false;
    }
    return self;
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
}

- (BOOL)connected {
    if (self.webSocket.readyState == SR_OPEN) {
        return true;
    } else {
        return false;
    }
}

- (void)connectionSocket {
    [self.webSocket close];
    self.webSocket.delegate = nil;
    self.closeSocketFoUser = false;
    
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:self.urlString]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)disconnectedLink {
    [self showMessageWithStr:@"断开连接"];
    
    [self closeHeartbeat];
    [self.webSocket close];
    self.webSocket = nil;
}

- (void)closeSocket {
    self.closeSocketFoUser = true;
    
    [self disconnectedLink];
}

// 发送数据
- (void)sendMessageAction:(NSString *)sender {
    if (self.webSocket.readyState == SR_OPEN) {
        [self.webSocket send:sender];
    }
}

// 发送心跳连接
- (void)sendPing:(NSData *)data {
    if (self.connected) {
        [self.webSocket sendPing:data];
    }
}

- (void)sendHeartbeatWithTime:(NSTimeInterval)time
                         data:(id)data {
    if (self.webSocket.readyState == SR_OPEN) {
        self.heartbeatData = data;
        [self addTimer:time];
    }
}

// 断开心跳连接
- (void)closeHeartbeat {
    if (self.closeSocketFoUser) {
        self.heartbeatData = nil;
    }
    [self.connectTimer invalidate];
    self.connectTimer = nil;
}

#pragma mark - SocketDelegate
// MARK: 连接成功
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self.reconnectionTimer invalidate];
    self.reconnectionTimer = nil;
    
//    [self closeHeartbeat];
//    [self sendHeartbeatWithTime:3 data:nil];
}

// MARK: 接收数据
- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message {
//    BMTLog(@"%@\n", message);
    
    NSError *error = nil;
    //NSJSONWritingPrettyPrinted:指定生成的JSON数据应使用空格旨在使输出更加可读。如果这个选项是没有设置,最紧凑的可能生成JSON表示。
    
    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
//    NSLog(@"jsonData：%@\ndic:%@\nerror：%@", jsonData, dic, error);
    NSDictionary *dataDic = dic;//[self replaceUnicode:dic];
    if (dataDic && self.receivesMessage) {
        self.receivesMessage(dataDic);
    } else {
        
    }
}

- (NSString *)replaceUnicode:(NSString *)unicodeStr {
    NSString *tempStr0 = [DEFUSE_EMPTY_STRING(unicodeStr) stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *tempStr1 = [tempStr0 stringByReplacingOccurrencesOfString:@"id" withString:@"userid"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData
                                                                    options:NSPropertyListImmutable
                                                                     format:NULL
                                                                      error:NULL];
    
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
}

// MARK: 连接失败
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {

    [self addReconnectionTimer:1];
}

// MARK: 关闭连接
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {

    if (!self.closeSocketFoUser) {
        [self connectionSocket];
    }
}

// MARK: 心跳连接成功
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
}

// socket 连接失败重联
- (void)addReconnectionTimer:(NSTimeInterval)timer {
    [self.reconnectionTimer invalidate];
    self.reconnectionTimer = nil;
    
    // 长连接定时器
    self.reconnectionTimer = [NSTimer scheduledTimerWithTimeInterval:timer target:self selector:@selector(connectionSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.reconnectionTimer forMode:NSRunLoopCommonModes];
}

// 发起 心跳连接 定时器
- (void)addTimer:(NSTimeInterval)timer {
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:timer target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

// 发起 心跳连接
- (void)longConnectToSocket {
    [self sendPing:self.heartbeatData];
}

- (void)showMessageWithStr:(NSString *)sender {
    NSLog(@"%@", sender);
}

// MARK: - 网络实时监听
- (void)listenNetWorkingStatus {
    [GLobalRealReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    [self realNetworkingStatus:status];
}

- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    
    if (status == RealStatusUnknown) {
        //wang luo duan kai
        [self disconnectedLink];
        if (self.netWorkStatus) {
            self.netWorkStatus(false);
        }
    } else if (status == RealStatusNotReachable) {
        [self disconnectedLink];
        
        if (!self.closeSocketFoUser) {
            [self connectionSocket];
        }
        if (self.netWorkStatus) {
            self.netWorkStatus(true);
        }
        
    } else {
        if (!self.closeSocketFoUser) {
            [self connectionSocket];
        }
        if (self.netWorkStatus) {
            self.netWorkStatus(true);
        }
    }
    
//    [self realNetworkingStatus:status];
}

- (void)realNetworkingStatus:(ReachabilityStatus)status{
    switch (status)
    {
        case RealStatusUnknown:
        {
            NSLog(@"~~~~~~~~~~~~~RealStatusUnknown");
            [self showNetworkStatusAlert:@"当前网络不可用"];
            break;
        }
            
        case RealStatusNotReachable:
        {
            NSLog(@"~~~~~~~~~~~~~RealStatusNotReachable");
            [self showNetworkStatusAlert:@"无网络,请检查网络连接"];
            break;
        }
            
        case RealStatusViaWWAN:
        {
            NSLog(@"~~~~~~~~~~~~~RealStatusViaWWAN");
            [self showNetworkStatusAlert:@"流量上网"];
            break;
        }
        case RealStatusViaWiFi:
        {
            NSLog(@"~~~~~~~~~~~~~RealStatusViaWiFi");
            //            [self showNetworkStatusAlert:@"WIFI上网,尽情挥霍吧小宝贝~"];
            break;
        }
        default:
            break;
    }
}

-(void)showNetworkStatusAlert:(NSString *)str {
    //我这里是网络变化弹出一个警报框，由于不知道怎么让widow加载UIAlertController，所以这里用UIAlertView替代了
//    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    [alert show];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

