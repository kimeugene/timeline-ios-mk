//
//  TLAppDelegate.m
//  TL_MK
//
//  Created by EKim on 3/21/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import "TLAppDelegate.h"
#import "TLCoreLocation.h"

@implementation TLAppDelegate
@synthesize operationQueue;
@synthesize bgTask;
@synthesize backgroundPing;
@synthesize motionManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create an instance of the global operation queue
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    // Begin the background pinging
    //TLBackgroundPingOperation *backgroundPing = [[TLBackgroundPingOperation alloc] init];
    //[self.operationQueue addOperation:backgroundPing];
    
    // Add the main view controller to the view stack

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.mainViewController = [[TLViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];
//    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                UITextAttributeTextColor: [UIColor colorWithRed:55/255.0 green:55/255.0 blue:55/255.0 alpha:0.9]
     }];
    
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startAccelerometerUpdates];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    
    NSLog(@"to background");
    
    
    UIApplication *app = [UIApplication sharedApplication];
    
    // Request permission to run in the background. Provide an
    // expiration handler in case the task runs long.
    // NSAssert(bgTask == UIBackgroundTaskInvalid, nil);
    
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize the cleanup call on the main thread in case
        // the task actually finishes at around the same time.
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (bgTask != UIBackgroundTaskInvalid)
            {
                [app endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    
    self.lastGPSUpdateTimestamp = [NSDate timeIntervalSinceReferenceDate];
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if(![backgroundPing isKindOfClass:[TLBackgroundPingOperation class]]) {
            NSLog(@"backgroundPing != nil");
            backgroundPing = [[TLBackgroundPingOperation alloc] init];
            [self.operationQueue addOperation:backgroundPing];
            
            while (1) {
                // The Keep-Alive code
                NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
                if(current - self.lastGPSUpdateTimestamp > 9*60) {
                    NSLog(@"elapsed timer for GPS background update. Asking GPS for an update.");
                    [backgroundPing getLocation];
                    NSLog(@"BGTime left: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
                    self.lastGPSUpdateTimestamp = [NSDate timeIntervalSinceReferenceDate];
                }                
                
                [self.motionManager startAccelerometerUpdates];
                sleep(1);
                
                // Patch into the accelerometer
                CMAccelerometerData *newData = [self.motionManager accelerometerData];
                NSLog(@"Accelerometer returned: x:%f y:%f z:%f", round([newData acceleration].x*100), round([newData acceleration].y*100), round([newData acceleration].z*100));
                [self.motionManager stopAccelerometerUpdates];

                if(abs(self.lastX) - abs(round([newData acceleration].x*100)) > 3 ||
                   abs(self.lastY) - abs(round([newData acceleration].y*100)) > 3 ||
                   abs(self.lastZ) - abs(round([newData acceleration].z*100)) > 3) {
                    NSLog(@"PING GPS!");
                    [backgroundPing getLocation];
                }
                
                self.lastX = round([newData acceleration].x*100);
                self.lastY = round([newData acceleration].y*100);
                self.lastZ = round([newData acceleration].z*100);
                    
                // Sleep for 60 until the next accelerometer check
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSNumber *freq = [defaults objectForKey:@"update_frequency"];
                int frequency = [freq intValue];
                NSLog(@"Current frequency: %d", frequency);
                
                sleep(frequency);
            }
            
        }
        
        // NSLog(@"App staus: applicationDidEnterBackground");
        // Synchronize the cleanup call on the main thread in case
        // the expiration handler is fired at the same time.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                [app endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });

    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"Terminated");

}

@end
