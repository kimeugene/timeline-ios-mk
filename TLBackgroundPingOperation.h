//
//  TBackgroundPingOperation.h
//  Timeline
//
//  Created by Fitz on 3/3/13.
//
//

#import <Foundation/Foundation.h>
#import "TLCoreLocation.h"

@interface TLBackgroundPingOperation : NSOperation <NSURLConnectionDelegate, TCoreLocationDelegate>
@property (nonatomic, retain) TLCoreLocation       *coreLocation;
@property (strong, retain)    NSURLConnection     *connection;
@property (strong, retain)    NSMutableURLRequest *request;
@property                     NSInteger            requestNumber;
@end
