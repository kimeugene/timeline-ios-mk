//
//  TLViewController.m
//  TL_MK
//
//  Created by EKim on 3/21/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import "TLViewController.h"
#import "ASIHTTPRequest.h"
#import "TLLocation.h"
#import "MBProgressHUD.h"
#import "TLConfig.h"
#import "TSQCalendarView.h"
#import "TSQTACalendarRowCell.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

@interface TLViewController ()

@end

@implementation TLViewController
@synthesize currentLocation;
@synthesize connection;
@synthesize request;
@synthesize currentDate;
@synthesize calendarViewContainer;
@synthesize calendarViewContainerShown;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	
    // Do any additional setup after loading the view, typically from a nib.
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    _mapView = [[MKMapView alloc] initWithFrame:frame];
    [self.view addSubview:_mapView];
    
    // Initialize the calendar view container
    CGRect calendarContainerFrame = CGRectMake(30, 80, 260, 296);
    calendarViewContainerShown = 0;
    self.calendarViewContainer = [[UIScrollView alloc] initWithFrame:calendarContainerFrame];
    [self.calendarViewContainer setBackgroundColor:[UIColor grayColor]];
    
    // Create the calendar and add it to the calendar view container
    CGRect calendarFrame = self.calendarViewContainer.frame;
    calendarFrame.origin.x = 1;
    calendarFrame.origin.y = 1;
    calendarFrame.size.width -= 2;
    calendarFrame.size.height -= 2;
    TSQCalendarView *calendarView = [[TSQCalendarView alloc] initWithFrame:calendarFrame];
    calendarView.rowCellClass = [TSQTACalendarRowCell class];
    calendarView.firstDate = [[NSDate date] dateByAddingTimeInterval:-(60*60*24*14)];
    calendarView.lastDate = [[NSDate date] dateByAddingTimeInterval:60 * 60 * 24 * 279.5]; // approximately 279.5 days in the future
    calendarView.backgroundColor = [UIColor colorWithRed:0.84f green:0.85f blue:0.86f alpha:1.0f];
    calendarView.pagingEnabled = YES;
    CGFloat onePixel = 1.0f / [UIScreen mainScreen].scale;
    calendarView.contentInset = UIEdgeInsetsMake(0.0f, onePixel, 0.0f, onePixel);
    calendarView.delegate = self;
    [self.calendarViewContainer addSubview:calendarView];
    
    [self addLeftRightStepButtons];
    [self addLeftRightDayButtons];
    [self addSettingsButton];

    UITapGestureRecognizer *navSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCalendar)];
    navSingleTap.numberOfTapsRequired = 1;
    [[self.navigationController.navigationBar.subviews objectAtIndex:1] setUserInteractionEnabled:YES];
    [[self.navigationController.navigationBar.subviews objectAtIndex:1] addGestureRecognizer:navSingleTap];
}

- (void)calendarView:(TSQCalendarView *)calendarView didSelectDate:(NSDate *)date
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [format stringFromDate:date];
    
    NSLog(@"Selected %@", dateString);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:dateString forKey:@"date"];
    [defaults synchronize];
    
    [self fetchLocationData];
    [self toggleCalendar];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setTitle:@"Back"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self fetchLocationData];
}


- (int)getZoomLevel
{
    #define MERCATOR_RADIUS 85445659.44705395
    #define MAX_GOOGLE_LEVELS 20

    CLLocationDegrees longitudeDelta = _mapView.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = _mapView.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 ) zoomer = 0;
    //  zoomer = round(zoomer);
    NSLog(@"Zoom level: %f", zoomer);
    return (int) zoomer;
}

- (void)fetchLocationData
{

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *email = [defaults objectForKey:@"email"];
    NSString *date = [defaults objectForKey:@"date"];

    // Load the currently selected date from settings
    NSDateFormatter *formatEncoded = [[NSDateFormatter alloc] init];
    [formatEncoded setDateFormat:@"yyyy-MM-dd"];
    NSDate *dateFormatted = [formatEncoded dateFromString:date];
    
    // Format the currently selected date for the navigation bar
    NSDateFormatter *formatDisplay = [[NSDateFormatter alloc] init];
    [formatDisplay setDateFormat:@"MMMM d, yyyy"];
    NSString *dateFormattedString = [formatDisplay stringFromDate:dateFormatted];
    [self setTitle:dateFormattedString];
    
    NSLog(@"fetchLocationData settingTitle to %@", date);

    // use different email for simulator
#if TARGET_IPHONE_SIMULATOR
#else
#endif
    
    
    NSString *url = [NSString stringWithFormat: @"http://ec2-50-16-36-166.compute-1.amazonaws.com/get/%@/%@/%i/750", email, date, [self getZoomLevel]];
    
    ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    __weak ASIHTTPRequest *request = _request;
    
    request.requestMethod = @"GET";
    //[request addRequestHeader:@"Content-Type" value:@"application/json"];
    //[request appendPostData:[json dataUsingEncoding:NSUTF8StringEncoding]];
    [request setDelegate:self];
    NSLog(@"Grabbing data points from %@", url);
    [request setCompletionBlock:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSString *responseString = [request responseString];
        [self plotTimeline:request.responseData];
        NSLog(@"Response: %@", responseString);
    }];
    [request setFailedBlock:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        NSError *error = [request error];
        NSLog(@"Error: %@", error.localizedDescription);
    }];
    
    [request startAsynchronous];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading data...";
}

- (void)toggleCalendar {
    if(calendarViewContainerShown) {
        [self.calendarViewContainer removeFromSuperview];
        calendarViewContainerShown = 0;
        return;
    }
    [self.view addSubview:self.calendarViewContainer];
    calendarViewContainerShown = 1;
}

- (void) addLeftRightStepButtons {
    
    // Add the left button
    UIButton *leftStepButton = [[UIButton alloc] initWithFrame:CGRectMake(100, self.view.frame.size.height - 48, 40, 40)];
    [leftStepButton setBackgroundColor:[UIColor colorWithRed:35.0/255
                                                       green:35.0/255
                                                        blue:35.0/255
                                                       alpha:0.96] ];
    [leftStepButton setTitle:@"<" forState:UIControlStateNormal];
    [leftStepButton addTarget:self action:@selector(previousStep) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftStepButton];
    
    // Add the right button
    UIButton *rightStepButton = [[UIButton alloc] initWithFrame:CGRectMake(176, self.view.frame.size.height - 48, 40, 40)];
    [rightStepButton setBackgroundColor:[UIColor colorWithRed:35.0/255
                                                        green:35.0/255
                                                         blue:35.0/255
                                                        alpha:0.96] ];
    [rightStepButton setTitle:@">" forState:UIControlStateNormal];
    [rightStepButton addTarget:self action:@selector(nextStep) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rightStepButton];
}

- (void) addLeftRightDayButtons {
    
    // Add the left button
    UIButton *leftDayButton = [[UIButton alloc] initWithFrame:CGRectMake(12, self.view.frame.size.height - 48, 40, 40)];
    [leftDayButton setBackgroundColor:[UIColor colorWithRed:35.0/255
                                                       green:35.0/255
                                                        blue:35.0/255
                                                       alpha:0.86] ];
    [leftDayButton setTitle:@"<<" forState:UIControlStateNormal];
    [leftDayButton addTarget:self action:@selector(previousDay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:leftDayButton];
    
    // Add the right button
    UIButton *rightDayButton = [[UIButton alloc] initWithFrame:CGRectMake(268, self.view.frame.size.height - 48, 40, 40)];
    [rightDayButton setBackgroundColor:[UIColor colorWithRed:35.0/255
                                                        green:35.0/255
                                                         blue:35.0/255
                                                        alpha:0.86] ];
    [rightDayButton setTitle:@">>" forState:UIControlStateNormal];
    [rightDayButton addTarget:self action:@selector(nextDay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rightDayButton];
}

- (void)previousStep
{
    [self navigateTimelineByStep:@"back"];
}

- (void)nextStep
{
    [self navigateTimelineByStep:@"forward"];
}

- (void)previousDay
{
    [self navigateTimelineByDay:@"back"];
}

- (void)nextDay
{
    [self navigateTimelineByDay:@"forward"];
}

- (void)navigateTimelineByDay:(NSString *)measure
{
    // Read currently selected date
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *dateString = [defaults objectForKey:@"date"];
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [format dateFromString:dateString];
    NSDate *yesterday;
    if([measure isEqualToString:@"back"])
        yesterday = [date dateByAddingTimeInterval:(60*60*24*1)*-1];
    else if([measure isEqualToString:@"forward"])
        yesterday = [date dateByAddingTimeInterval:60*60*24*1];
    
    // Write date
    NSString *newDate = [format stringFromDate:yesterday];
    [defaults setObject:newDate forKey:@"date"];
    [defaults synchronize];
    
    // Fetch the new lcoation data
    [self fetchLocationData];

}

- (void)navigateTimelineByStep:(NSString *)direction
{
    NSInteger cnt = self.timeline.count;
    
    NSLog(@"Current index: %i", self.currentLocation.index);
    NSLog(@"Timeline size: %i", cnt);
    
    int new_index = -1;
    
    if ([direction isEqualToString:@"forward"])
    {
        new_index = self.currentLocation.index + 1;
        if (new_index >= cnt) {
            return;
        }
    }
    
    if ([direction isEqualToString:@"back"])
    {
        new_index = self.currentLocation.index - 1;
        if (new_index <= 0) {
            return;
        }
    }
    
    if (new_index > 0){
        NSNumber *latitude = [[self.timeline objectAtIndex:new_index] objectAtIndex:0];
        NSNumber *longitude = [[self.timeline objectAtIndex:new_index] objectAtIndex:1];
        NSString *time = [[self.timeline objectAtIndex:new_index] objectAtIndex:2];
        
        NSLog(@"New lat: %@", latitude);
        NSLog(@"New long: %@", longitude);
        
        NSString *address = @"venue";
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude.doubleValue;
        coordinate.longitude = longitude.doubleValue;
        TLLocation *annotation = [[TLLocation alloc] initWithName:time address:address coordinate:coordinate];
        
        // remove previous location
        [_mapView removeAnnotation:self.currentLocation];
        
        self.currentLocation = annotation;
        self.currentLocation.index = new_index;
        [_mapView addAnnotation:annotation];
    }
}

- (void)addSettingsButton
{
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"?"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(settings)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)settings
{
    self.settingsViewController = [[TLSettingsViewController alloc] init];
    [self.navigationController pushViewController:self.settingsViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    
    NSLog(@"Got memory warning");
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ec2-50-16-36-166.compute-1.amazonaws.com/post?terminated"]];
    self.request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [self.request setHTTPMethod:@"GET"];
    
    connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                 delegate:self
                                         startImmediately:YES];
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)plotTimeline:(NSData *)responseData {
    [_mapView setDelegate:self];

    for (id<MKAnnotation> annotation in _mapView.annotations) {
        [_mapView removeAnnotation:annotation];
    }
    [_mapView removeOverlays:_mapView.overlays];
    
    self.timeline = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    
    NSInteger cnt = self.timeline.count;
    
    if (cnt > 0) {
        NSNumber *first_latitude = [[self.timeline objectAtIndex:0] objectAtIndex:0];
        NSNumber *first_longitude = [[self.timeline objectAtIndex:0] objectAtIndex:1];
        NSString *first_time = [[self.timeline objectAtIndex:0] objectAtIndex:2];
        NSString *first_address = @"address";
        
        CLLocationCoordinate2D first_coordinate;
        first_coordinate.latitude = first_latitude.doubleValue;
        first_coordinate.longitude = first_longitude.doubleValue;
        TLLocation *first_annotation = [[TLLocation alloc] initWithName:first_time address:first_address coordinate:first_coordinate];
        
        // keep track of current location
        self.currentLocation = first_annotation;
        self.currentLocation.index = 0;
        
        [_mapView addAnnotation:first_annotation];
        
        
        CLLocationCoordinate2D coordinateArray[cnt];
        
        for(int i = 0; i < cnt; i++) {
            coordinateArray[i] = CLLocationCoordinate2DMake([[[self.timeline objectAtIndex:i] objectAtIndex:0] doubleValue], [[[self.timeline objectAtIndex:i] objectAtIndex:1] doubleValue]);
        }
        
        
        
        MKPolyline *routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:cnt];
        [_mapView setVisibleMapRect:[routeLine boundingMapRect]];
        
        [_mapView addOverlay:routeLine];
        
        
        NSNumber *last_latitude = [[self.timeline lastObject] objectAtIndex:0];
        NSNumber *last_longitude = [[self.timeline lastObject] objectAtIndex:1];
        NSString *last_time = [[self.timeline lastObject] objectAtIndex:2];
        NSString *last_address = @"address";
        
        CLLocationCoordinate2D last_coordinate;
        last_coordinate.latitude = last_latitude.doubleValue;
        last_coordinate.longitude = last_longitude.doubleValue;
        TLLocation *last_annotation = [[TLLocation alloc] initWithName:last_time address:last_address coordinate:last_coordinate];
        [_mapView addAnnotation:last_annotation];
        
    }
}

- (MKOverlayView*)mapView:(MKMapView*)mapView viewForOverlay:(id <MKOverlay>)overlay
{

    MKPolylineView* lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    lineView.strokeColor = [UIColor blueColor];
    lineView.lineWidth = 7;
    return lineView;
}


@end
