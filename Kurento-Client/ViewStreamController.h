//
//  ViewController.h
//  Kurento-Client
//
//  Created by Mac Developer001 on 10/3/16.
//  Copyright © 2016 com.wangu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraContainerView;
@interface ViewStreamController : UIViewController


@property (weak, nonatomic) IBOutlet UITextField *sessionField;
@property (weak, nonatomic) IBOutlet CameraContainerView *viewContainer;

@end

