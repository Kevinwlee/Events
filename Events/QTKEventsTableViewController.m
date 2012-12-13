//
//  QTKEventsTableViewController.m
//  Events
//
//  Created by Kevin Lee on 10/19/12.
//  Copyright (c) 2012 Qteko. All rights reserved.
//

#import "QTKEventsTableViewController.h"

@interface QTKEventsTableViewController ()
@property (nonatomic, retain) EKEventStore *eventStore;
@property (nonatomic, retain) EKCalendar *defaultCalendar;
@property (nonatomic, retain) NSMutableArray *eventsList;
@property (nonatomic, retain) EKEventViewController *detailViewController;

- (NSArray *) fetchEventsForToday;
- (IBAction) addEvent:(id)sender;

@end

@implementation QTKEventsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Events List";
	
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addEvent:)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    self.navigationController.delegate = self;
	self.eventStore = [[EKEventStore alloc] init];
	self.eventsList = [[NSMutableArray alloc] initWithArray:0];
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        // Get the default calendar from store.
        self.defaultCalendar = [self.eventStore defaultCalendarForNewEvents];
        [self.eventsList addObjectsFromArray:[self fetchEventsForToday]];
        [self scheduleNotificationsForEvents];
        [self.tableView reloadData];
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *) fetchEventsForToday {
	NSDate *startDate = [NSDate date];
	
	// endDate is 7 days = 60*60*24*7 seconds = 86400 seconds from startDate
	NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:604800];
	
	// Create the predicate. Pass it the default calendar.
	NSArray *calendarArray = [NSArray arrayWithObject:self.defaultCalendar];
    
	NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:startDate endDate:endDate
                                                                    calendars:calendarArray];
	
	// Fetch all events that match the predicate.
	NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];
	return events;
}

- (void)scheduleNotificationsForEvents {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    for (EKEvent *event in self.eventsList) {
        if (!event.isAllDay) {
            [self addNotificationForEvent:event];
        }
    }
}

- (void)addNotificationForEvent:(EKEvent*)event {
    
    UILocalNotification *localNotificaiton = [[UILocalNotification alloc] init];
    [event.endDate dateByAddingTimeInterval:60];
    localNotificaiton.fireDate = [event.endDate dateByAddingTimeInterval:60];
    localNotificaiton.timeZone =  [NSTimeZone defaultTimeZone];

    NSLog(@"Fire Date: %@", localNotificaiton.fireDate);
    localNotificaiton.alertBody = @"Was that productive?";
    localNotificaiton.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotificaiton];
    
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.eventsList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.textLabel.text = [[self.eventsList objectAtIndex:indexPath.row] title];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.detailViewController = [[EKEventViewController alloc] initWithNibName:nil bundle:nil];
	self.detailViewController.event = [self.eventsList objectAtIndex:indexPath.row];
	self.detailViewController.allowsEditing = YES;
	[self.navigationController pushViewController:self.detailViewController animated:YES];

}

#pragma mark -
#pragma mark Navigation Controller delegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	// if we are navigating back to the rootViewController, and the detailViewController's event
	// has been deleted -  will title being NULL, then remove the events from the eventsList
	// and reload the table view. This takes care of reloading the table view after adding an event too.
	if (viewController == self && self.detailViewController.event.title == NULL) {
		[self.eventsList removeObject:self.detailViewController.event];
		[self.tableView reloadData];
	}
}


#pragma mark -
#pragma mark Add a new event

// If event is nil, a new event is created and added to the specified event store. New events are
// added to the default calendar. An exception is raised if set to an event that is not in the
// specified event store.
- (void)addEvent:(id)sender {
	// When add button is pushed, create an EKEventEditViewController to display the event.
	EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
	
	// set the addController's event store to the current event store.
	addController.eventStore = self.eventStore;
	
	// present EventsAddViewController as a modal view controller
	[self presentViewController:addController animated:YES completion:nil];
	
	addController.editViewDelegate = self;
	
}


#pragma mark -
#pragma mark EKEventEditViewDelegate
// Overriding EKEventEditViewDelegate method to update event store according to user actions.
- (void)eventEditViewController:(EKEventEditViewController *)controller
          didCompleteWithAction:(EKEventEditViewAction)action {
	
	NSError *error = nil;
	EKEvent *thisEvent = controller.event;
	
	switch (action) {
		case EKEventEditViewActionCanceled:
			// Edit action canceled, do nothing.
			break;
			
		case EKEventEditViewActionSaved:
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.eventsList addObject:thisEvent];
			}
			[controller.eventStore saveEvent:controller.event span:EKSpanThisEvent error:&error];
			[self.tableView reloadData];
            [self addNotificationForEvent:thisEvent];
			break;
			
		case EKEventEditViewActionDeleted:
			if (self.defaultCalendar ==  thisEvent.calendar) {
				[self.eventsList removeObject:thisEvent];
			}
			[controller.eventStore removeEvent:thisEvent span:EKSpanThisEvent error:&error];
			[self.tableView reloadData];
			break;
			
		default:
			break;
	}
	[controller dismissViewControllerAnimated:YES completion:nil];
}


// Set the calendar edited by EKEventEditViewController to our chosen calendar - the default calendar.
- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
	EKCalendar *calendarForEdit = self.defaultCalendar;
	return calendarForEdit;
}

@end
