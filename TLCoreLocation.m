//
//  TCoreLocationController.m
//  Timeline
//
//  Created by Fitz on 3/2/13.
//
//

#import "TLCoreLocation.h"

@implementation TLCoreLocation
@synthesize locMgr;
@synthesize delegate;

- (id)init {
    self = [super init];
    if(self != nil) {
        self.locMgr = [[CLLocationManager alloc] init];
        self.locMgr.delegate = self;
        [self.locMgr setDistanceFilter:2];
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    if([self.delegate conformsToProtocol:@protocol(TCoreLocationDelegate)]) {
        // Before we notify the delegate, filter out GPS coordinates that were retrieved
        // more than 15 seconds ago. This happens when the LocationManager boots up and
        // uses old, cached location data just to get you a speedy response.
        NSDate *eventDate = newLocation.timestamp;
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        if (abs(howRecent) > 15.0) {
            return;
        }
        [self.delegate locationUpdate:newLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
        if([self.delegate conformsToProtocol:@protocol(TCoreLocationDelegate)]) {
            [self.delegate locationError:error];
        }
}

@end
