//
//  ViewController.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import "CreateStreamController.h"
#import <KurentoToolbox/KurentoToolbox.h>
#import "WebRTCClient.h"
#import <AVFoundation/AVFoundation.h>
#import "CameraContainerView.h"

#import "UIView+Toast.h"

@interface CreateStreamController () <RTCDelegate> {
    UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, strong) UIView* localVideoView;

@end

@implementation CreateStreamController  {
    WebRTCClient *rtcClient;
}

@synthesize sessionView;
@synthesize viewContainer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    rtcClient = [[WebRTCClient alloc] init];
    rtcClient.delegate = self;
    
    NSURL *wsURI = [NSURL URLWithString:@"wss://kms.searchandmap.com:8443/cast"];
    [rtcClient initClient:wsURI];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewWillDisappear:(BOOL)animated {
    [rtcClient closeClient];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createAction:(id)sender {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *sessionId = [NSString stringWithFormat:@"%d", (int)interval];
    self.sessionView.text = sessionId;
    [rtcClient createStream:sessionId];
}

- (IBAction)cancelAction:(id)sender {
    [rtcClient stopStream];
}
- (IBAction)switchCameraAction:(id)sender {
    [rtcClient switchCamera];
}

// RTCDelegate Method

- (void)onStreamCreated {
    
}

- (void)onStopCommunication {
    
}

- (void)onAddLocalStream:(UIView *)videoView {
    if (self.localVideoView != nil) {
        [self.localVideoView removeFromSuperview];
    }
    self.localVideoView = videoView;
    [self.viewContainer addSubview:self.localVideoView];
    CGAffineTransform finalTransform = CGAffineTransformIdentity;
    videoView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.01, 0.01), finalTransform);
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        videoView.transform = finalTransform;
    } completion:nil];
}

- (void)onRemoveLocalStream {
    if (self.localVideoView != nil) {
        [self.localVideoView removeFromSuperview];
    }
    self.localVideoView = nil;
}

- (void)onAddRemoteStream:(UIView *)videoView {

}

- (void)onRemoveRemoteStream {
    
}

- (void)viewDidLayoutSubviews {
    if (self.localVideoView) {
        self.localVideoView.frame = self.viewContainer.bounds;
    }

}

- (void)onCreateFailed:(NSString *)msg {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)onViewFailed:(NSString *)msg {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)onSocketOpenFailed {
    self.sessionView.text = @"";
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Socket Open Failed" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:true completion:nil];
}

- (void)onSocketNotReady {
    self.sessionView.text = @"";
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Socket is not ready" message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:true completion:nil];
}

@end
