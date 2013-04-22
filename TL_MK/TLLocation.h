//
//  TLMyLocation.h
//  TL_MK
//
//  Created by EKim on 3/25/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface TLLocation : NSObject <MKAnnotation>

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;
- (MKMapItem*)mapItem;

@property (nonatomic) int index;

@end

