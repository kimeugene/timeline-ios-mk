//
//  TLAppDelegate.h
//  TL_MK
//
//  Created by EKim on 3/21/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TLBackgroundPingOperation.h"

@interface TLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property UIBackgroundTaskIdentifier bgTask;

@end
