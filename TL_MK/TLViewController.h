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

@property (strong, retain)    NSURLConnection     *connection;
@property (strong, retain)    NSMutableURLRequest *request;

@property (nonatomic, retain) NSString *currentDate;
@property                     NSInteger currentZoomLevel;
@property (nonatomic, retain) UIScrollView *calendarViewContainer;
@property                     NSInteger calendarViewContainerShown;

@property (nonatomic, retain) UIImageView *timelineControlLine;
@property (nonatomic, retain) UIImageView *timelineControlPlay;
@property (nonatomic, retain) UIImageView *timelineControlRewind;
@property (nonatomic, retain) UIImageView *timelineControlFastForward;

@property CGRect timelineControlLineFrame;
@property CGRect timelineControlPlayFrame;
@property CGRect timelineControlRewindFrame;
@property CGRect timelineControlFastForwardFrame;


@property BOOL hudVisibility;

@end
