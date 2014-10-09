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
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

CLPlacemark *thePlacemark;
MKRoute *routeDetails;
NSTimer *timer;
int timeTick;
int timer_value;
int totaltime;
bool hasprompt;
bool hasspaned;

@synthesize mapView=_mapView;

//load everything when the view loads
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
    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [_timer setDelegate:self];
    [_timer setEnabled: NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


//when the map updates location, use this function
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.04;
    mapRegion.span.longitudeDelta = 0.04;
    if (!hasspaned) {
        [mapView setRegion:mapRegion animated: YES];
        hasspaned = true;
    }
}


//create a placemark for the annotation
- (void)addAnnotation:(CLPlacemark *)placemark {
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
    point.title = [placemark.addressDictionary objectForKey:@"Street"];
    point.subtitle = [placemark.addressDictionary objectForKey:@"City"];
    [self.mapView addAnnotation:point];
}

//when the user types an address in the field and presses return
- (IBAction)addressField:(UITextField *)sender {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:sender.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            thePlacemark = [placemarks lastObject];
            float spanX = .04;
            float spanY = .04;
            
            //find the coordinates and calculate the route and ETA
            MKCoordinateRegion region;
            region.center.latitude = thePlacemark.location.coordinate.latitude;
            region.center.longitude = thePlacemark.location.coordinate.longitude;
            region.span = MKCoordinateSpanMake(spanX, spanY);
            [self.mapView setRegion:region animated:YES];
            [self addAnnotation:thePlacemark];
            MKDirectionsRequest *directions = [[MKDirectionsRequest alloc]init];
            
            //set the source of the directions
            _source = [MKMapItem mapItemForCurrentLocation];
            [directions setSource:_source];
            
            //placemark and destination
            _placemark = [[MKPlacemark alloc] initWithPlacemark:thePlacemark];
            _destination = [[MKMapItem alloc]initWithPlacemark:_placemark];
            
            //set the destination
            [directions setDestination:_destination];
            directions.transportType = MKDirectionsTransportTypeWalking;
            MKDirections *finaldirections = [[MKDirections alloc] initWithRequest:directions];
            MKDirections *finaldirections2 = [[MKDirections alloc] initWithRequest:directions];
            
            //calculate ETA
            [finaldirections calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
             {
                 NSTimeInterval estimatedTravelTimeInSeconds = response.expectedTravelTime;
                 totaltime = estimatedTravelTimeInSeconds;
                 NSString *strFromInt;
                 if (totaltime > 60) {
                     strFromInt = [NSString stringWithFormat:@"%d min",(int)floor(totaltime/60)];
                 }
                 else {
                     strFromInt = [NSString stringWithFormat:@"%d sec",totaltime];
                 }
                 _timer.text = strFromInt;
             }];
            
            //calculate the route
            [finaldirections2 calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"%@", error);
                } else {
                    [_mapView removeOverlays:_mapView.overlays];
                    routeDetails = response.routes.lastObject;
                    [self.mapView addOverlay:routeDetails.polyline];
                }
            }];
        }
    }];
}


//creating a pin for the map
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

//render the directions line (route line)
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer  * routeLineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:routeDetails.polyline];
    routeLineRenderer.strokeColor = [UIColor blueColor];
    routeLineRenderer.lineWidth = 5;
    return routeLineRenderer;
}

//the "Walk Me" button
- (IBAction)startWalk:(id)sender {
    hasprompt = false;
    timeTick = 0;
    [_timer setEnabled: NO];
    timer_value = totaltime;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

//every time the timer ticks (every second), run this method
-(void)tick {
    timeTick++;
    NSString *number = @"7144171047";
    CLPlacemark *tempplacemark = _placemark;
    CLLocation *location = tempplacemark.location;
    CLLocation *currentlocation = [[CLLocation alloc]initWithLatitude:_mapView.userLocation.location.coordinate.latitude longitude:_mapView.userLocation.location.coordinate.longitude];
    double distance = [currentlocation distanceFromLocation: location];
    if (distance < 30) {
        hasprompt = true;
        [timer invalidate];
        [_timer setEnabled: YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You have safely reached your destination."
                                                        message:@"Congrats!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    else if (timeTick == timer_value) {
        [_timer setEnabled: YES];
        NSString *phoneNumber = [@"tel://" stringByAppendingString:number];
        NSArray *numbers = @[number];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
    }
    
    else if (timer_value - timeTick < 60 && hasprompt == false && timeTick < timer_value) {
        hasprompt = true;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Almost out of Time!"
                                                        message:@"You have 60 seconds left to get home, would you like to add 5 more minutes?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:nil];
        [alert addButtonWithTitle:@"Yes"];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [alert show];
    }
}

//The add time alert
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

//"Stop" button
- (IBAction)reset:(id)sender {
    [timer invalidate];
    [_timer setEnabled: YES];
    _timer.text = @"";
}
@end
