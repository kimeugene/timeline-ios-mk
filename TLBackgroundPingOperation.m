//
//  TBackgroundPingOperation.m
//  Timeline
//
//  Created by Fitz on 3/3/13.
//
//

#import "TLBackgroundPingOperation.h"

@implementation TLBackgroundPingOperation
@synthesize coreLocation;
@synthesize connection;
@synthesize request;
@synthesize requestNumber;

- (void)main {
    requestNumber = 1;
    
    // Initialize our Core Location interface
    coreLocation = [[TLCoreLocation alloc] init];
    coreLocation.delegate = self;
    
    // Start the run loop so this operation stays active
    NSLog(@"TBackgroundPingOperation: main() executed");
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    [runLoop run];

    // Set a timer that executes every 5 minutes
    //[NSTimer scheduledTimerWithTimeInterval:5
    //                                 target:self
     ///                              selector:@selector(getSingleLocation)
        //                           userInfo:nil
          //                          repeats:YES];
    
    [self getLocation];
}

- (void)getLocation
{
    NSLog(@"inside getLocation");
    
    // Fire off the first one
    [coreLocation.locMgr startUpdatingLocation];
}

- (void)locationUpdate:(CLLocation *)location {    
    // NSLog(@"TBackgroundPingOperation locationUpdate: location.timestamp: %@", location.timestamp);
    
    BOOL valid = [self isValidLocation:location withOldLocation:self.oldLocation];
    
    if (valid == YES) {
        NSLog(@"TBackgroundPingOperation locationUpdate: %@", [location description]);
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ec2-50-16-36-166.compute-1.amazonaws.com/post"]];
        self.request = [[NSMutableURLRequest alloc] initWithURL:url];
        NSDate *date = [[NSDate alloc] init];
        NSTimeInterval currentTimestamp = [date timeIntervalSince1970];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *email = [defaults objectForKey:@"email"];
        
        // Post:
        NSString *postString = [NSString stringWithFormat:@"email=%@&timestamp=%i&long=%f&lat=%f", email, abs(currentTimestamp), location.coordinate.longitude, location.coordinate.latitude];
        [self.request setHTTPMethod:@"POST"];
        [self.request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [self.request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-Length"];
        [self.request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Get
        // [self.request setHTTPMethod:@"GET"];
        
        connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                     delegate:self
                                             startImmediately:YES];
        requestNumber++;
        
        
        self.oldLocation = location;
        
    }
    else {
        NSLog(@"TBackgroundPingOperation invalid location");
    }

    [coreLocation.locMgr stopUpdatingLocation];
    
}

- (BOOL)isValidLocation:(CLLocation *)newLocation withOldLocation:(CLLocation *)oldLocation {
    
    // Filter out nil locations
    if (!newLocation) return NO;
    
    // Filter out points by invalid accuracy
    if (newLocation.horizontalAccuracy < 0) return NO;
    if (newLocation.horizontalAccuracy > 66) return NO;
    
    // Filter out points by invalid accuracy
#if !TARGET_IPHONE_SIMULATOR
    if (newLocation.verticalAccuracy < 0) return NO;
#endif
    
    // Filter out points that are out of order
    NSTimeInterval secondsSinceLastPoint = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
    if (secondsSinceLastPoint < 0) return NO;
    
    // Make sure the update is new not cached
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return NO;
    
    if (oldLocation){
        // Check to see if old and new are the same
        if ((oldLocation.coordinate.latitude == newLocation.coordinate.latitude) && (oldLocation.coordinate.longitude == newLocation.coordinate.longitude))
            return NO;
        
        CLLocationDistance dist = [newLocation distanceFromLocation:self.oldLocation];
        
        if(dist > newLocation.horizontalAccuracy)
        {
            //.....
        }
        
    }
    
    return YES;
    
}

- (void)locationError:(NSError *)error {
    NSLog(@"TBackgroundPingOperation locationError: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"TBackgroundPingOperation request succeeded. Finished loading.");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"TBackgroundPingOperation request failed. connection:didFailWithError: %@", [error description]);
}

@end
