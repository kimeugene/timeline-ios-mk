//
//  TLViewController.h
//  TL_MK
//
//  Created by EKim on 3/21/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TLLocation.h"
#import "TLSettingsViewController.h"

@interface TLViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) MKMapView *mapView;
@property (nonatomic, retain) MKPolyline *routeLine;
@property (nonatomic, retain) MKPolylineView *routeLineView;

@property (nonatomic, retain) TLLocation *currentLocation;
@property (nonatomic, retain) NSArray *timeline;
@property (nonatomic, retain) TLSettingsViewController *settingsViewController;


@end
