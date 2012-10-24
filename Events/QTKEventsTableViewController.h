//
//  QTKEventsTableViewController.h
//  Events
//
//  Created by Kevin Lee on 10/19/12.
//  Copyright (c) 2012 Qteko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@interface QTKEventsTableViewController : UITableViewController <UINavigationControllerDelegate, EKEventEditViewDelegate>

@end
