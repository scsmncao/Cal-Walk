//
//  TableViewController.h
//  CalWalk
//
//  Created by Simon Cao on 10/5/14.
//  Copyright (c) 2014 CalHacks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>

@interface TableViewController : UITableViewController <UITableViewDataSource, ABPeoplePickerNavigationControllerDelegate>
@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) ABPeoplePickerNavigationController *picker;
@property (nonatomic, strong) NSDictionary *dictContactDetails;

@property (nonatomic, weak) IBOutlet UILabel *lblContactName;
@property (nonatomic, weak) IBOutlet UITableView *tblContactDetails;

@end
