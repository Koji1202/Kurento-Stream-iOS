//
//  ViewController.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import "ViewStreamController.h"
#import <KurentoToolbox/KurentoToolbox.h>
#import "WebRTCClient.h"
#import <AVFoundation/AVFoundation.h>

#import "CameraContainerView.h"

#import "UIView+Toast.h"

@interface ViewStreamController () <RTCDelegate> {
    UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, strong) UIView* remoteVideoView;

@end

@implementation ViewStreamController  {
    WebRTCClient *rtcClient;
}


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

- (IBAction)viewAction:(id)sender {
    NSString *sessionId = self.sessionField.text;    
    [rtcClient viewStream:sessionId];
    [self.sessionField endEditing:true];
}

- (IBAction)cancelAction:(id)sender {
    [self.sessionField endEditing:true];
    [rtcClient stopStream];
}

// RTCDelegate Method

- (void)onStreamCreated {
    
}

- (void)onStopCommunication {
    
}

- (void)onAddLocalStream:(UIView *)videoView {
    
}

- (void)onRemoveLocalStream {
    
}

- (void)onAddRemoteStream:(UIView *)videoView {
    if (self.remoteVideoView != nil) {
        [self.remoteVideoView removeFromSuperview];
    }
    self.remoteVideoView = videoView;
    [self.viewContainer addSubview:self.remoteVideoView];
    CGAffineTransform finalTransform = CGAffineTransformIdentity;
    videoView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.01, 0.01), finalTransform);
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        videoView.transform = finalTransform;
    } completion:nil];
}

- (void)onRemoveRemoteStream {
    if (self.remoteVideoView != nil) {
        [self.remoteVideoView removeFromSuperview];
    }
    self.remoteVideoView = nil;
}

- (void)viewDidLayoutSubviews {
    if (self.remoteVideoView) {
        self.remoteVideoView.frame = self.viewContainer.bounds;
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
