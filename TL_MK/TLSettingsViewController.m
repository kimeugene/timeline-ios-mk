//
//  TLSettingsViewController.m
//  TL_MK
//
//  Created by Fitz on 5/6/13.
//  Copyright (c) 2013 kim. All rights reserved.
//

#import "TLSettingsViewController.h"

@interface TLSettingsViewController ()

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *frequencyField;

@end

@implementation TLSettingsViewController
@synthesize emailField;
@synthesize frequencyField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)hideKeyboard
{
    NSLog(@"hideKeyboard");
    [emailField resignFirstResponder];
    [frequencyField resignFirstResponder];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"Settings"];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    // Add a Save button
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                       style:UIBarButtonItemStyleDone
                                                                      target:self
                                                                      action:@selector(save)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Track the pixels
    int yCurrent =  54;
    
    // Create the font
    UIFont *font = [UIFont boldSystemFontOfSize:12];
    UIFont *inputFont = [UIFont systemFontOfSize:16];
    
    
    // Add the Email label
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, yCurrent, 296, 24)];
    [emailLabel setBackgroundColor:[UIColor whiteColor]];
    [emailLabel setTextColor:[UIColor grayColor]];
    [emailLabel setText:@"USER EMAIL:"];
    [emailLabel setFont:font];
    [self.view addSubview:emailLabel];
    yCurrent += 24;
    yCurrent += 6;
    
    // Add the Email text input
    self.emailField = [[UITextField alloc] initWithFrame:CGRectMake(12, yCurrent, 296, 32)];
    [emailField setBackgroundColor:[UIColor whiteColor]];
    [emailField setBorderStyle:UITextBorderStyleLine];
    [emailField setTextColor:[UIColor blackColor]];
    [emailField setText:@""];
    [emailField setFont:inputFont];
    [self.view addSubview:emailField];
    yCurrent += 32;
    yCurrent += 12;
    
    // Add the Frequency label
    UILabel *frequencyLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, yCurrent, 296, 24)];
    [frequencyLabel setBackgroundColor:[UIColor whiteColor]];
    [frequencyLabel setTextColor:[UIColor grayColor]];
    [frequencyLabel setText:@"FREQUENCY (MIN):"];
    [frequencyLabel setFont:font];
    [self.view addSubview:frequencyLabel];
    yCurrent += 24;
    yCurrent += 6;
    
    // Add the Frequency text input
    frequencyField = [[UITextField alloc] initWithFrame:CGRectMake(12, yCurrent, 64, 32)];
    [frequencyField setBackgroundColor:[UIColor whiteColor]];
    [frequencyField setBorderStyle:UITextBorderStyleLine];
    [frequencyField setTextColor:[UIColor blackColor]];
    [frequencyField setText:@"5"];
    [frequencyField setFont:inputFont];
    [self.view addSubview:frequencyField];
    yCurrent += 32;
    yCurrent += 12;

    [self loadSettings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)save
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *email     = [emailField text];
    NSString *frequency = [frequencyField text];

    [defaults setObject:email     forKey:@"email"];
    [defaults setObject:frequency forKey:@"frequency"];

    [defaults synchronize];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) loadSettings
{
    // Load settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [emailField setText:[defaults objectForKey:@"email"]];
    [frequencyField setText:[defaults objectForKey:@"frequency"]];
}

@end
