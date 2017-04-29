//
//  RTCPeer.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/5/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//


#import "NSDictionary+Json.h"
#import <SocketRocket/SRWebSocket.h>

@protocol NBMRoomClientDelegate;

@class NBMWebRTCPeer;
@class WebRTCClient;
@class RTCIceCandidate;

@interface RTCPeer : NSObject <NBMWebRTCPeerDelegate>

- (void)initPeer:(WebRTCClient *)client;
- (void)generateOffer:(NSString *)chatId;
- (void)processAnswer:(NSString *)sdpAnswer;
- (void)addICECandidate:(RTCIceCandidate *)candidate;
- (void)selectCamera:(Boolean)bBack;

@property (nonatomic, strong) NBMWebRTCPeer *webRTCPeer;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) WebRTCClient *client;
@property (nonatomic, assign) Boolean isCreator;
@property (nonatomic, assign) Boolean bBackCamera;

@end
