//
//  WebRTCClient.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "WebRTCClient.h"
#import <AVFoundation/AVFoundation.h>


#import <WebRTC/WebRTC.h>

#define CALLSTATE_NONE 0
#define CALLSTATE_STREAM 1

static NSTimeInterval kChannelTimeoutInterval = 5.0;
static NSTimeInterval kChannelKeepaliveInterval = 20.0;

typedef NS_ENUM(NSInteger, TransportChannelState) {
    // State when connecting.
    TransportChannelStateOpening,
    // State when connection is established and ready for use.
    TransportChannelStateOpen,
    // State when disconnecting.
    TransportChannelStateClosing,
    // State when disconnected.
    TransportChannelStateClosed
};

@interface WebRTCClient() {
    
}
@property (nonatomic, strong) RTCPeerConnectionFactory *factory;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, readwrite) TransportChannelState channelState;
@property (nonatomic, strong) NSTimer *keepAliveTimer;
@end

@implementation WebRTCClient {
    NBMJSONRPCClient *jsonRpcClient;
    NBMJSONRPCClientConfiguration *clientConfig;
    SRWebSocket *webSocket;
    NSString *currentFrom;
    NSInteger callState;
    Boolean backCamera;
}

@synthesize delegate;
@synthesize rtcPeer;

- (void)initClient:(NSURL *)wsURI {
    self.openChannelTimeout = kChannelTimeoutInterval;
    self.keepAliveInterval = kChannelKeepaliveInterval;
    self.processingQueue = dispatch_queue_create("eu.nubomedia.websocket.processing", DISPATCH_QUEUE_SERIAL);
    self.channelState = TransportChannelStateClosed;
    
    NSMutableURLRequest *wsRequest = [[NSMutableURLRequest alloc] initWithURL:wsURI cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_openChannelTimeout];
    
    SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURLRequest:wsRequest protocols:@[@"chat"] allowsUntrustedSSLCertificates:YES];
    [newWebSocket setDelegateDispatchQueue:self.processingQueue];
    newWebSocket.delegate = self;
    [newWebSocket open];
    
    callState = CALLSTATE_NONE;
    backCamera = false;
}

- (void)switchCamera {
    if (backCamera)
        backCamera = false;
    else
        backCamera = true;
    if (rtcPeer != nil) {
        
        [rtcPeer selectCamera:backCamera];
        
        if (callState != CALLSTATE_NONE) {
            self.localStream = rtcPeer.webRTCPeer.localStream;
            id<NBMRenderer> renderer = [self rendererForStream:self.localStream];
            if (renderer == NULL)
                return;
            self.localRenderer = renderer;
            [delegate onAddLocalStream:self.localRenderer.rendererView];
        }        
    }
    
}

- (void)closeClient {
    if (_channelState != TransportChannelStateClosed) {
        [webSocket close];
        self.channelState = TransportChannelStateClosing;
    }
    else {
        [self cleanupChannel];
    }
}

- (void)cleanupChannel
{
    webSocket.delegate = nil;
    webSocket = nil;
    self.channelState = TransportChannelStateClosed;
    
    [self invalidateTimer];
}

- (void)scheduleTimer
{
    [self invalidateTimer];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:self.keepAliveInterval target:self selector:@selector(handlePingTimer:) userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    self.keepAliveTimer = timer;
}

- (void)invalidateTimer
{
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
}

- (void)handlePingTimer:(NSTimer *)timer
{
    if (webSocket) {
        [self sendPing];
        [self scheduleTimer];
    } else {
        [self invalidateTimer];
    }
}

- (void)sendPing
{
    //check for socket status
    if (webSocket.readyState == SR_OPEN) {
        NSLog(@"Send ping");
        [webSocket sendPing:nil];
    }
}

/*------------------------------------------------------------------------------
//  Send Command
------------------------------------------------------------------------------*/

- (id<NBMRenderer>)rendererForStream:(RTCMediaStream *)stream
{
    if (stream == NULL)
        return NULL;
    
    id<NBMRenderer> renderer = nil;
    RTCVideoTrack *videoTrack = [stream.videoTracks firstObject];
    
    renderer = [[NBMEAGLRenderer alloc] initWithDelegate:self];
    
    renderer.videoTrack = videoTrack;
    
    return renderer;
}

- (void)createStream:(NSString *)sessionId {
    if (_channelState != TransportChannelStateOpen) {
        [self.delegate onSocketNotReady];
        return;
    }    
    
    if (callState != CALLSTATE_NONE) {
        return;
    }
    
    callState = CALLSTATE_STREAM;
    
    rtcPeer = [[RTCPeer alloc] init];
    [rtcPeer initPeer:self];
    rtcPeer.isCreator = true;
    rtcPeer.sessionId = sessionId;
    
    self.sessionId = sessionId;
    
    Boolean bMediaStarted = [rtcPeer.webRTCPeer startLocalMedia];
    if (bMediaStarted) {
        [rtcPeer selectCamera:backCamera];
        self.localStream = rtcPeer.webRTCPeer.localStream;
        id<NBMRenderer> renderer = [self rendererForStream:self.localStream];
        if (renderer == NULL)
            return;
        self.localRenderer = renderer;
        [delegate onAddLocalStream:self.localRenderer.rendererView];
    }
    
    [rtcPeer generateOffer:rtcPeer.sessionId];
    
}

- (void)viewStream:(NSString *)sessionId {
    if (_channelState != TransportChannelStateOpen) {
        [self.delegate onSocketNotReady];
        return;
    }
    
    if (callState != CALLSTATE_NONE) {
        return;
    }
    
    callState = CALLSTATE_STREAM;
    
    rtcPeer = [[RTCPeer alloc] init];
    [rtcPeer initPeer:self];
    rtcPeer.isCreator = false;
    rtcPeer.sessionId = sessionId;
    
    self.sessionId = sessionId;
    
    [rtcPeer generateOffer:rtcPeer.sessionId];
    
}

- (void)stopStream {
    NSLog(@"call stop");
    NSDictionary *param = @{@"id": @"stop"};
    NSString *command = [param getJsonString:true];
    [self sendMessage:command];
    [self stopCommunication];
}

- (void)sendMessage:(NSString *)message {
    if (message) {
        if (_channelState == TransportChannelStateOpen) {
            DDLogVerbose(@"WebSocket: did send message: %@", message);
            [webSocket send:message];
        } else {
            DDLogWarn(@"Socket is not ready to send a message!");
        }
    }
}

/*------------------------------------------------------------------------------
//  JSON RPC Delegate
------------------------------------------------------------------------------*/

- (void)presenterResponse:(NSDictionary *)message {
    NSString *response = [message objectForKey:@"response"];
    if ([response isEqualToString:@"accepted"]) {
        NSLog(@"Presenter Success");
        NSString *sdpAnswer = [message objectForKey:@"sdpAnswer"];
        [rtcPeer processAnswer:sdpAnswer];
        [delegate onStreamCreated];
    } else {
        callState = CALLSTATE_NONE;
        [self.delegate onCreateFailed:[message objectForKey:@"message"]];
    }
}

- (void)viewerResponse:(NSDictionary *)message {
    NSString *response = [message objectForKey:@"response"];
    if ([response isEqualToString:@"accepted"]) {
        NSLog(@"Viwer Success");
        NSString *sdpAnswer = [message objectForKey:@"sdpAnswer"];
        [rtcPeer processAnswer:sdpAnswer];
    } else {
        callState = CALLSTATE_NONE;
        [self.delegate onViewFailed:[message objectForKey:@"message"]];
    }
}

- (void)iceCandidate:(NSDictionary *)message {
    NSDictionary *data = [message objectForKey:@"candidate"];
    NSString *sdpMid = [data objectForKey:@"sdpMid"];
    int sdpMLineIndex = (int)[[data objectForKey:@"sdpMLineIndex"] integerValue];
    NSString *sdp = [data objectForKey:@"candidate"];

    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
    
    [rtcPeer addICECandidate:candidate];
}

- (void)didAddRemoteStream: (RTCMediaStream*)remoteStream {
    
    self.remoteStream = remoteStream;
    
    id<NBMRenderer> renderer = [self rendererForStream:self.remoteStream];
    if (renderer == NULL)
        return;
    
    self.remoteRenderer = renderer;
    [delegate onAddRemoteStream:self.remoteRenderer.rendererView];
    
}

- (void)didRemoveRemoteStream {
    self.remoteStream = nil;
    self.remoteRenderer = nil;
    [delegate onRemoveRemoteStream];
}

- (void)stopCommunication {
    callState = CALLSTATE_NONE;
    NSLog(@"stopCommunication called.");
    [delegate onStopCommunication];
    
    if (rtcPeer.isCreator) {
        self.localStream = nil;
        self.localRenderer = nil;
        [delegate onRemoveLocalStream];
    } else {
        self.remoteStream = nil;
        self.remoteRenderer = nil;
        [delegate onRemoveRemoteStream];
    }
    
}


/*------------------------------------------------------------------------------
 //  WebSocket Delegate
 ------------------------------------------------------------------------------*/

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    webSocket = newWebSocket;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.channelState = TransportChannelStateOpen;
        //Keep-alive
        [self scheduleTimer];
    });
    NSLog(@"socket opened.");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"socket error. %@", error);
    [self.delegate onSocketOpenFailed];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanupChannel];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if (![message isKindOfClass:[NSString class]])
            return;
        NSError *jsonError;
        NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
        NSString *messageId = [data objectForKey:@"id"];
        NSLog(@"socket data received - %@", messageId);
        if ([messageId isEqualToString:@"presenterResponse"]) {
            [self presenterResponse:data];
        }
        if ([messageId isEqualToString:@"viewerResponse"]) {
            [self viewerResponse:data];
        }
        if ([messageId isEqualToString:@"stopCommunication"]) {
            [self stopCommunication];
        }
        if ([messageId isEqualToString:@"iceCandidate"]) {
            if (data != nil) {
                [self iceCandidate:data];
            }
        }
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"socket closed.");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cleanupChannel];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"ping received. ");
}


/*------------------------------------------------------------------------------
 //  WebSocket Delegate
 ------------------------------------------------------------------------------*/

- (void)renderer:(id<NBMRenderer>)renderer streamDimensionsDidChange:(CGSize)dimensions {
}

- (void)rendererDidReceiveVideoData:(id<NBMRenderer>)renderer {
}

@end
