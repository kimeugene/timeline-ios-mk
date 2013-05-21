//
//  TLAppDelegate.h
//  TL_MK
//
//  Created by EKim on 3/21/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TLViewController.h"
#import "TLBackgroundPingOperation.h"


@interface TLAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) TLViewController *mainViewController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property UIBackgroundTaskIdentifier bgTask;

@property (strong, nonatomic) TLBackgroundPingOperation *backgroundPing;
@property (strong, retain)    NSURLConnection     *connection;
@property (strong, retain)    NSMutableURLRequest *request;

@end
