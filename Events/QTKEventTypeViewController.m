//
//  QTKEventTypeViewController.m
//  Events
//
//  Created by Kevin Lee on 10/19/12.
//  Copyright (c) 2012 Qteko. All rights reserved.
//

#import "QTKEventTypeViewController.h"

@interface QTKEventTypeViewController ()

@end

@implementation QTKEventTypeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)skipTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
@end
