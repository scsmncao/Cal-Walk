//
//  ViewController.m
//  CalWalk
//
//  Created by Simon Cao on 10/4/14.
//  Copyright (c) 2014 CalHacks. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

CLPlacemark *thePlacemark;
MKRoute *routeDetails;
int timeTick;
int timer_value;
bool hasprompt;
NSTimer *timer;

@synthesize mapView=_mapView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.mapView.delegate = self;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    _mapView.showsUserLocation = YES;
    _mapView.delegate = self;
    [_timer setDelegate:self];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.04;
    mapRegion.span.longitudeDelta = 0.04;
    
    [mapView setRegion:mapRegion animated: NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addAnnotation:(CLPlacemark *)placemark {
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
    point.title = [placemark.addressDictionary objectForKey:@"Street"];
    point.subtitle = [placemark.addressDictionary objectForKey:@"City"];
    [self.mapView addAnnotation:point];
}


- (IBAction)addressField:(UITextField *)sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:sender.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            thePlacemark = [placemarks lastObject];
            float spanX = .5;
            float spanY = .5;
            MKCoordinateRegion region;
            region.center.latitude = thePlacemark.location.coordinate.latitude;
            region.center.longitude = thePlacemark.location.coordinate.longitude;
            region.span = MKCoordinateSpanMake(spanX, spanY);
            [self.mapView setRegion:region animated:YES];
            [self addAnnotation:thePlacemark];
            MKDirectionsRequest *directions = [[MKDirectionsRequest alloc]init];
            _source = [MKMapItem mapItemForCurrentLocation];
            [directions setSource:_source];
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithPlacemark:thePlacemark];
            _destination = [[MKMapItem alloc]initWithPlacemark:placemark];
            [directions setDestination:_destination];
            directions.transportType = MKDirectionsTransportTypeWalking;
            MKDirections *finaldirections = [[MKDirections alloc] initWithRequest:directions];
            MKDirections *finaldirections2 = [[MKDirections alloc] initWithRequest:directions];
            [finaldirections calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
             {
                 NSTimeInterval estimatedTravelTimeInSeconds = response.expectedTravelTime;
                 NSInteger time = estimatedTravelTimeInSeconds;
                 NSString *strFromInt = [NSString stringWithFormat:@"%d",time];
                 _timer.text = strFromInt;
             }];
            [finaldirections2 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                if (error) {
                    // Handle Error
                } else {
                    [_mapView removeOverlays:_mapView.overlays];
                    routeDetails = response.routes.lastObject;
                    [self.mapView addOverlay:routeDetails.polyline];
                }
            }];
        }
    }];
}



-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor blueColor];
    routeLineRenderer.lineWidth = 5;
    return routeLineRenderer;
}
- (IBAction)startWalk:(id)sender {
    hasprompt = false;
    timeTick = 0;
    [_timer setEnabled: NO];
    NSString *time = _timer.text;
    timer_value = [time intValue];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        hasprompt = true;
        return;
    }
    if (buttonIndex == 1) {
        timer_value += 300;
        return;
    }
}


-(void)tick {
    timeTick++;
    NSString *number = @"5863601035";
    /*MKDirectionsRequest *directions = [[MKDirectionsRequest alloc]init];
    _updatedsource =[MKMapItem mapItemForCurrentLocation];
    [directions setSource:_updatedsource];
    [directions setDestination:_destination];
    directions.transportType = MKDirectionsTransportTypeWalking;
    MKDirections *updateddirections = [[MKDirections alloc] initWithRequest:directions];
    __block NSInteger time;
    [updateddirections calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
     {
         NSTimeInterval estimatedTravelTimeInSeconds = response.expectedTravelTime;
         time = estimatedTravelTimeInSeconds;
     }];
    int myTime = time;
    printf("%i", myTime);
    if (myTime < 20) {
        timeTick = timer_value + 1;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You have reached your destination."
                                                        message:@"Congrats!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    if (timeTick > timer_value) {
        [timer invalidate];
        [_timer setEnabled: YES];
    }*/
    
    if (timeTick == timer_value) {
        [_timer setEnabled: YES];
        NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
        NSArray *numbers = @[number];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
    
    else if (timer_value - timeTick < 30 && hasprompt == false && timeTick < timer_value) {
        hasprompt = true;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Close to Destination"
                                                        message:@"You have 30 seconds left to get home, would you like to add 5 more minutes?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Yes"];
        [alert show];
    }
}
@end
