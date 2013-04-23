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
    
    // Set a timer that executes every 5 minutes
    [NSTimer scheduledTimerWithTimeInterval:5*60
                                     target:self
                                   selector:@selector(getSingleLocation)
                                   userInfo:nil
                                    repeats:YES];
    
    // Fire off the first one
    [self getSingleLocation];
    
    // Start the run loop so this operation stays active
    NSLog(@"TBackgroundPingOperation: main() executed");
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    [runLoop run];
}

- (void)getSingleLocation
{
    [coreLocation.locMgr startUpdatingLocation];
}

- (void)locationUpdate:(CLLocation *)location {    
    NSLog(@"TBackgroundPingOperation locationUpdate: location.timestamp: %@", location.timestamp);
    NSLog(@"TBackgroundPingOperation locationUpdate: %@", [location description]);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ec2-50-16-36-166.compute-1.amazonaws.com/post"]];
    self.request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSDate *date = [[NSDate alloc] init];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970];
    
    // Post:
    NSString *postString = [NSString stringWithFormat:@"email=fitz5@timeline.pwn&timestamp=%i&long=%f&lat=%f", abs(currentTimestamp), location.coordinate.longitude, location.coordinate.latitude];
    [self.request setHTTPMethod:@"POST"];
    [self.request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-Length"];
    [self.request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Get
    // [self.request setHTTPMethod:@"GET"];
    
    connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                 delegate:self
                                         startImmediately:YES];
    requestNumber++;
    
    
    [coreLocation.locMgr stopUpdatingLocation];
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
