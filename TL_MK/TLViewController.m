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

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

@interface TLViewController ()

@end

@implementation TLViewController
@synthesize currentLocation;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view, typically from a nib.
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    self.mapView = [[MKMapView alloc] initWithFrame:frame];
    NSLog(@"MKMapView will take the frame: %@", NSStringFromCGRect(frame));
    [self.view addSubview:self.mapView];
    NSLog(@"yes");
}

- (void)navigateTimeline:(NSString *)direction
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
        NSLog(@"New lat: %@", latitude);
        NSLog(@"New long: %@", longitude);
        
        NSString *description = @"description";
        NSString *address = @"address";
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = latitude.doubleValue;
        coordinate.longitude = longitude.doubleValue;
        TLLocation *annotation = [[TLLocation alloc] initWithName:description address:address coordinate:coordinate];
        
        // remove previous location
        [_mapView removeAnnotation:self.currentLocation];
        
        self.currentLocation = annotation;
        self.currentLocation.index = new_index;
        [_mapView addAnnotation:annotation];
    }
}

- (IBAction)leftNav:(id)sender
{
    [self navigateTimeline:@"back"];
}

- (IBAction)rightNav:(id)sender
{
    [self navigateTimeline:@"forward"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)plotTimeline:(NSData *)responseData {
    for (id<MKAnnotation> annotation in _mapView.annotations) {
        [_mapView removeAnnotation:annotation];
    }
    
    self.timeline = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];

    NSInteger cnt = self.timeline.count;

    if (cnt > 0) {
        NSNumber *first_latitude = [[self.timeline objectAtIndex:0] objectAtIndex:0];
        NSNumber *first_longitude = [[self.timeline objectAtIndex:0] objectAtIndex:1];
        NSString *first_description = @"description";
        NSString *first_address = @"address";
        
        CLLocationCoordinate2D first_coordinate;
        first_coordinate.latitude = first_latitude.doubleValue;
        first_coordinate.longitude = first_longitude.doubleValue;
        TLLocation *first_annotation = [[TLLocation alloc] initWithName:first_description address:first_address coordinate:first_coordinate];
        
        // keep track of current location
        self.currentLocation = first_annotation;
        self.currentLocation.index = 0;
        
        [_mapView addAnnotation:first_annotation];

        
        CLLocationCoordinate2D coordinateArray[cnt];
        
        for(int i = 0; i < cnt; i++) {
            coordinateArray[i] = CLLocationCoordinate2DMake([[[self.timeline objectAtIndex:i] objectAtIndex:0] doubleValue], [[[self.timeline objectAtIndex:i] objectAtIndex:1] doubleValue]);
        }
        

        
        self.routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:cnt];
        [self.mapView setVisibleMapRect:[self.routeLine boundingMapRect]];
        
        [self.mapView addOverlay:self.routeLine];
        

    
    
        NSNumber *last_latitude = [[self.timeline lastObject] objectAtIndex:0];
        NSNumber *last_longitude = [[self.timeline lastObject] objectAtIndex:1];
        NSString *last_description = @"description";
        NSString *last_address = @"address";
        
        CLLocationCoordinate2D last_coordinate;
        last_coordinate.latitude = last_latitude.doubleValue;
        last_coordinate.longitude = last_longitude.doubleValue;
        TLLocation *last_annotation = [[TLLocation alloc] initWithName:last_description address:last_address coordinate:last_coordinate];
        [_mapView addAnnotation:last_annotation];
    
    }
}

- (MKOverlayView*)mapView:(MKMapView*)theMapView viewForOverlay:(id <MKOverlay>)overlay
{
    MKPolylineView* lineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
    lineView.fillColor = [UIColor whiteColor];
    lineView.strokeColor = [UIColor whiteColor];
    lineView.lineWidth = 4;
    return lineView;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MyLocation";
    if ([annotation isKindOfClass:[TLLocation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"pic.png"];
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    TLLocation *location = (TLLocation*)view.annotation;
    
    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    [location.mapItem openInMapsWithLaunchOptions:launchOptions];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [self setTitle:@"Saturday, April 4th"];
    
    NSString *email = @"fitz5@timeline.pwn";

    // use different email for simulator
    #if !(TARGET_IPHONE_SIMULATOR)
        NSString *email = @"emulator@timeline.pwn";
    #endif

    NSString *url = [NSString stringWithFormat: @"http://ec2-50-16-36-166.compute-1.amazonaws.com/get/%@/2013-04-05", email];

    ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    __weak ASIHTTPRequest *request = _request;
    
    request.requestMethod = @"GET";
    //[request addRequestHeader:@"Content-Type" value:@"application/json"];
    //[request appendPostData:[json dataUsingEncoding:NSUTF8StringEncoding]];
    [request setDelegate:self];
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

@end
