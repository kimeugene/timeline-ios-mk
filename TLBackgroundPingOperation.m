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
    
    int code = [self isValidLocation:location withOldLocation:self.oldLocation];
    
    // get paths from root direcory
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    // get documents path
    NSString *documentsPath = [paths objectAtIndex:0];
    // get the path to our Data/plist file
    NSString *plistPath = [documentsPath stringByAppendingPathComponent:@"datapoints.plist"];
    
    NSDate *date = [[NSDate alloc] init];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970];
    
    NSMutableArray *data;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath])
    {
        data = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
        NSLog(@"data from plist: %lu", (unsigned long)data.count);
        
        // upload data to the server once we have at least 10 data points
        
        if (data.count % 10 == 0)
        {
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ec2-50-16-36-166.compute-1.amazonaws.com/post"]];
            self.request = [[NSMutableURLRequest alloc] initWithURL:url];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *email = [defaults objectForKey:@"email"];
             
            // Post:
            NSString *data_points = [data componentsJoinedByString:@","];
            NSString *postString = [NSString stringWithFormat:@"email=%@&data_points=%@", email, data_points];
            
            NSLog(@"Sending data to the server: %@", data_points);
            
            [self.request setHTTPMethod:@"POST"];
            [self.request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [self.request setValue:[NSString stringWithFormat:@"%d", [postString length]] forHTTPHeaderField:@"Content-Length"];
            [self.request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
             
            // Get
            // [self.request setHTTPMethod:@"GET"];
            NSError        *error = nil;
            NSURLResponse  *response = nil;
            
            [NSURLConnection sendSynchronousRequest: self.request returningResponse: &response error: &error];
            
            if (error)
            {
                NSLog(@"Sending data error:%@", error);
            }
            else
            {
                // delete plist file
                NSLog(@"Removing plist file");
                [data removeAllObjects];
                [[NSFileManager defaultManager] removeItemAtPath:plistPath error:nil];
            }
 
        }
    }

    NSArray *datapoint = [[NSArray alloc] initWithObjects:
                           [NSString stringWithFormat:@"%d", abs(currentTimestamp)],
                           [NSString stringWithFormat:@"%f", location.coordinate.longitude],
                           [NSString stringWithFormat:@"%f",location.coordinate.latitude],
                           [NSString stringWithFormat:@"%d", code], nil];
        
    NSString *datapoint_string = [datapoint componentsJoinedByString:@"|"];
        
    [data addObject:datapoint_string];
    [data writeToFile:plistPath atomically:YES];
        
    NSLog(@"TBackgroundPingOperation locationUpdate: %@", [location description]);
        
    self.oldLocation = location;
        
    [coreLocation.locMgr stopUpdatingLocation];
    
}

- (int)isValidLocation:(CLLocation *)newLocation withOldLocation:(CLLocation *)oldLocation {
    
    // Filter out nil locations
    if (!newLocation) return 1;
    
    // Filter out points by invalid accuracy
    if (newLocation.horizontalAccuracy < 0) return 2;
    if (newLocation.horizontalAccuracy > 66) return 3;
    
    // Filter out points by invalid accuracy
#if !TARGET_IPHONE_SIMULATOR
    if (newLocation.verticalAccuracy < 0) return 4;
#endif
    
    // Filter out points that are out of order
    NSTimeInterval secondsSinceLastPoint = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
    if (secondsSinceLastPoint < 0) return 5;
    
    // Make sure the update is new not cached
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return 6;
    
    if (oldLocation){
        // Check to see if old and new are the same
        if ((oldLocation.coordinate.latitude == newLocation.coordinate.latitude) && (oldLocation.coordinate.longitude == newLocation.coordinate.longitude))
            return 7;
        
        CLLocationDistance dist = [newLocation distanceFromLocation:self.oldLocation];
        
        if(dist > newLocation.horizontalAccuracy)
        {
            return 8;
        }
        
    }
    
    return 0;
    
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
