//
//  BMTSocket.h
//
//  Created by 王章仲 on 2018/1/22.
//

#import <Foundation/Foundation.h>
@class SRWebSocket;

typedef void(^ReceivesMessage)(NSDictionary *newsDic);
typedef void(^NetWorkStatus)(BOOL online);
@interface BMTSocket : NSObject

@property (nonatomic, strong) SRWebSocket *webSocket;

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign, readonly) BOOL connected;

// 连接
- (void)connectionSocket;
// 断开
- (void)closeSocket;

// 发送数据
- (void)sendMessageAction:(NSString *)sender;
// 发送心跳连接
- (void)sendPing:(NSData *)data;
- (void)sendHeartbeatWithTime:(NSTimeInterval)time data:(id)data;
- (void)closeHeartbeat;

/**
 * 接收数据
 */
@property (nonatomic, copy) ReceivesMessage receivesMessage;
/**
 * 网络是否接通
 */
@property (nonatomic, copy) NetWorkStatus netWorkStatus;
@end
