//
//  RTCPeer.m
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/5/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RTCPeer.h"

#import "WebRTCClient.h"

#import <KurentoToolbox/KurentoToolbox.h>

#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCSessionDescription.h>

@implementation RTCPeer {
    int nICECandidateSocketSendCount;    
}

@synthesize webRTCPeer;
@synthesize sessionId;

- (void)initPeer:(WebRTCClient *)client {
    NBMMediaConfiguration *mediaConfig = [NBMMediaConfiguration defaultConfiguration];
    
    webRTCPeer = [[NBMWebRTCPeer alloc] initWithDelegate:self configuration:mediaConfig];    
    self.client = client;
    nICECandidateSocketSendCount = 0;
}

- (void)selectCamera:(Boolean)bBack {
    self.bBackCamera = bBack;
    if (webRTCPeer != nil) {
        NBMCameraPosition cameraPosition = NBMCameraPositionBack;
        if (bBack)
            cameraPosition = NBMCameraPositionBack;
        else
            cameraPosition = NBMCameraPositionFront;
        if ([webRTCPeer hasCameraPositionAvailable:cameraPosition])
            [webRTCPeer selectCameraPosition:cameraPosition];
    }
}
- (void)generateOffer:(NSString *)chatId {
    sessionId = chatId;
    [webRTCPeer generateOffer:sessionId];
}
- (void)processAnswer:(NSString *)sdpAnswer {
    [webRTCPeer processAnswer:sdpAnswer connectionId:sessionId];
}

- (void)addICECandidate:(RTCIceCandidate *)candidate {
    [webRTCPeer addICECandidate:candidate connectionId:sessionId];
}

- (NSString*) stringForSocketReadyState:(SRReadyState) readyState {
    if (readyState == SR_CONNECTING) {
        return @"Socket Connecting";
    } else if (readyState == SR_OPEN) {
        return @"Socket Open";
    } else if (readyState == SR_CLOSING) {
        return @"Socket Closing";
    } else if (readyState == SR_CLOSED) {
        return @"Socket Closed";
    } else {
        return @"Socket State Unknown";
    }
}

/**
 *  Called when a new ICE is locally gathered for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param candidate  The locally gathered ICE.
 *  @param connection The connection for which the ICE was gathered.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer hasICECandidate:(RTCIceCandidate *)candidate forConnection:(NBMPeerConnection *)connection {
    
    NSDictionary *payload = @{@"sdpMLineIndex" :  [NSNumber numberWithInteger:candidate.sdpMLineIndex],
                              @"sdpMid" : candidate.sdpMid,
                              @"candidate" : candidate.sdp};
    NSDictionary *message = @{@"id" : @"onIceCandidate",
                              @"candidate" : payload};
    NSLog(@"Send content: %@", [message getJsonString:false]);
    [self.client sendMessage:[message getJsonString:false]];
}

/**
 *  Called any time a connection's state changes.
 *
 *  @param peer       The peer sending the message.
 *  @param state      The new notified state.
 *  @param connection The connection whose state has changed.
 */
- (void)webrtcPeer:(NBMWebRTCPeer *)peer iceStatusChanged:(RTCIceConnectionState)state ofConnection:(NBMPeerConnection *)connection {
    
}

/**
 *  Called when media is received on a new stream from remote peer.
 *
 *  @param peer         The peer sending the message.
 *  @param remoteStream A RTCMediaStream instance.
 *  @param connection   The connection related to the stream.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didAddStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection {
    NSLog(@"Added Stream");
    if (!self.isCreator)
        [self.client didAddRemoteStream:remoteStream];
}

/**
 *  Called when the peer successfully generated an new offer for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param sdpOffer   The newly generated RTCSessionDescription offer.
 *  @param connection The connection for which the offer was generated.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didGenerateOffer:(RTCSessionDescription *)sdpOffer forConnection:(NBMPeerConnection *)connection {
    if (!self.isCreator) {
        // Viewer
        NSDictionary *message = @{@"id" : @"viewer",
                                  @"session" : self.sessionId,
                                  @"sdpOffer" : sdpOffer.description};
        
        [self.client sendMessage:[message getJsonString:false]];
    } else {
        // Creater
        NSDictionary *message = @{@"id" : @"presenter",
                                  @"session" : self.sessionId,
                                  @"sdpOffer" : sdpOffer.description};
        
        [self.client sendMessage:[message getJsonString:false]];
    }
}


/**
 *  Called when the peer successfully generated a new answer for a connection.
 *
 *  @param peer       The peer sending the message.
 *  @param sdpAnswer  The newly generated RTCSessionDescription offer.
 *  @param connection The connection for which the aswer was generated.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didGenerateAnswer:(RTCSessionDescription *)sdpAnswer forConnection:(NBMPeerConnection *)connection {
    
}


/**
 *  Called when a remote peer close a stream.
 *
 *  @param peer         The peer sending the message.
 *  @param remoteStream A RTCMediaStream instance.
 *  @param connection   The connection related to the stream.
 */
- (void)webRTCPeer:(NBMWebRTCPeer *)peer didRemoveStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection {
    NSLog(@"Removed Stream");
    [self.client didRemoveRemoteStream];
}

- (void)webRTCPeer:(NBMWebRTCPeer *)peer didAddDataChannel:(RTCDataChannel *)dataChannel {
    
}

@end
