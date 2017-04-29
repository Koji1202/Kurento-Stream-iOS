//
//  WebRTCClient.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KurentoToolbox/KurentoToolbox.h>
#import <SocketRocket/SRWebSocket.h>

#import "NSDictionary+Json.h"
#import "RTCPeer.h"

@class RTCMediaStream;
@protocol NBMRendererDelegate;

@protocol RTCDelegate
- (void)onStreamCreated;
- (void)onStopCommunication;
- (void)onAddLocalStream:(UIView *)videoView;
- (void)onRemoveLocalStream;
- (void)onAddRemoteStream:(UIView *)videoView;
- (void)onRemoveRemoteStream;

- (void)onCreateFailed:(NSString *)msg;
- (void)onViewFailed:(NSString *)msg;

- (void)onSocketOpenFailed;
- (void)onSocketNotReady;

@end

@interface WebRTCClient : NSObject <SRWebSocketDelegate, NBMRendererDelegate>

- (void)initClient:(NSURL *)wsURI;
- (void)closeClient;
- (void)createStream:(NSString *)sessionId;
- (void)viewStream:(NSString *)sessionId;
- (void)stopStream;

- (void)switchCamera;

- (void)sendMessage:(NSString *)message;

- (void)didAddRemoteStream: (RTCMediaStream*)remoteStream;
- (void)didRemoveRemoteStream;

@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, retain) id <RTCDelegate> delegate;
@property (nonatomic, strong) RTCPeer *rtcPeer;
@property (nonatomic, strong) id<NBMRenderer> localRenderer;
@property (nonatomic, strong) id<NBMRenderer> remoteRenderer;
@property (nonatomic, strong) RTCMediaStream *localStream;
@property (nonatomic, strong) RTCMediaStream *remoteStream;

@property (nonatomic, assign) NSTimeInterval openChannelTimeout;
@property (nonatomic, assign) NSTimeInterval keepAliveInterval;

@end
