//
//  QRCodeScanViewController.m
//  QRCodeScan
//
//  Created by 王章仲 on 2018/11/26.
//  Copyright © 2018 王章仲. All rights reserved.
//

#import "QRCodeScanViewController.h"
#import <AVFoundation/AVFoundation.h>

#define KScreen_Width [UIScreen mainScreen].bounds.size.width
#define KScreen_Height [UIScreen mainScreen].bounds.size.height

@interface QRCodeScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession * session;//输入输出的中间桥梁
}
@end

@implementation QRCodeScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Scan";
    
    [self loadCustomViews];
}

- (void)loadCustomViews {
    CGFloat qrWidth = KScreen_Width/2;
    
    //添加扫描器
    [self createScanMediaWithSize:qrWidth];
    
    //设置扫描视图
    [self setQRCodeUIWithSize:qrWidth];
    
}

/**
 创建扫描器
 */
- (void)createScanMediaWithSize:(CGFloat)size {
    NSError *error;
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
    //设置敏感区域
    output.rectOfInterest = CGRectMake(((KScreen_Height - size)/2)/KScreen_Height, ((KScreen_Width - size)/2)/KScreen_Width, (size)/KScreen_Height, (size)/KScreen_Width);

    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    session = [[AVCaptureSession alloc] init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    //添加输入输出流
    [session addInput:input];
    [session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [session startRunning];
}

//设置扫描器视图
- (void)setQRCodeUIWithSize:(CGFloat)size {
    UIView *aView = [[UIView alloc] init];
    [self.view addSubview:aView];
    aView.backgroundColor = [UIColor blackColor];
    
    UIView *bView = [[UIView alloc] init];
    [self.view addSubview:bView];
    bView.backgroundColor = [UIColor blackColor];
    
    UIView *cView = [[UIView alloc] init];
    [self.view addSubview:cView];
    cView.backgroundColor = [UIColor blackColor];
    
    UIView *dView = [[UIView alloc] init];
    [self.view addSubview:dView];
    dView.backgroundColor = [UIColor blackColor];
    
    aView.frame = CGRectMake(0, 0, (KScreen_Width - size)/2, KScreen_Height);
    bView.frame = CGRectMake(((KScreen_Width - size)/2 + size), 0, (KScreen_Width - size)/2, KScreen_Height);
    cView.frame = CGRectMake((KScreen_Width - size)/2, 0, size, (KScreen_Height - size)/2);
    dView.frame = CGRectMake((KScreen_Width - size)/2, (KScreen_Height - size)/2 + size, size, (KScreen_Height - size)/2);
    
    aView.alpha = 0.5;
    bView.alpha = 0.5;
    cView.alpha = 0.5;
    dView.alpha = 0.5;
}

//AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if ((metadataObjects != nil) && ([metadataObjects count] > 0)) {
        [session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        //输出扫描字符串
        NSLog(@"%@", metadataObject.stringValue);
        //在此处处理扫描出得内容，比如跳转至webView，或者显示数据等。
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
