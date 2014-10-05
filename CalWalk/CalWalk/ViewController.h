//
//  ViewController.h
//  CalWalk
//
//  Created by Simon Cao on 10/4/14.
//  Copyright (c) 2014 CalHacks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController <MKMapViewDelegate, UITextFieldDelegate, MFMessageComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *timer;
- (IBAction)startWalk:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *walkme;
@property (strong, nonatomic) MKMapItem *source;
@property (strong, nonatomic) MKMapItem *destination;
@property (strong, nonatomic) MKMapItem *updatedsource;
@property (weak, nonatomic) IBOutlet UITextField *destinationField;

@property (strong, nonatomic) NSString *allSteps;

- (IBAction)addressField:(UITextField *)sender;
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay;



@end

