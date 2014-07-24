//
//  AddVideosViewController.m
//  AddContacts
//
//  Created by Jason Bandy on 4/16/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "AddVideosViewController.h"
#import "FeatureAPI.h"

@interface AddVideosViewController ()

@property (weak, nonatomic) IBOutlet UITextField *durationTextField;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (weak, nonatomic) IBOutlet UILabel *doneLabel;
@property (weak, nonatomic) IBOutlet UIButton *addVideosButton;

@property (strong, nonatomic) FeatureAPI *featureAPI;

@property (nonatomic, getter=isAddingVideos) BOOL addingVideos;

// Properties for hiding keyboard by touching off keyboard
@property (strong, nonatomic) UIGestureRecognizer *tap;
@property (strong, nonatomic) UITextField *textFieldWithFocus;

@end

@implementation AddVideosViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.durationTextField.delegate = self;
    
    [self markVideoOperationAsEnded];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.tap.cancelsTouchesInView = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    self.featureAPI.delegate = self;
    
    if (self.isAddingVideos) {
        UIApplication.sharedApplication.idleTimerDisabled = YES;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    self.featureAPI.delegate = nil;
    
    UIApplication.sharedApplication.idleTimerDisabled = NO;
}

#pragma mark Internal Helpers
-(void)dismissKeyboard {
    [self.textFieldWithFocus resignFirstResponder];
}

-(void)markVideoOperationAsStarting {
    self.addingVideos = YES;
    
    self.durationTextField.enabled = NO;
    self.addVideosButton.enabled = NO;
    [self.addVideosButton setTitle:@"Adding Videos..." forState:UIControlStateNormal];
    
    self.doneLabel.hidden = YES;
    self.progressBarView.progressTintColor = [UIColor greenColor];
    [self.progressBarView setProgress:0.0f animated:NO];
    
    UIApplication.sharedApplication.idleTimerDisabled = YES;
}

-(void)markVideoOperationAsEnded {
    self.addingVideos = NO;
    
    self.durationTextField.text = @"";
    self.durationTextField.enabled = YES;
    self.addVideosButton.enabled = YES;
    [self.addVideosButton setTitle:@"Add Videos" forState:UIControlStateNormal];
    
    UIApplication.sharedApplication.idleTimerDisabled = NO;
}

#pragma mark Utilities
-(BOOL)isTextFieldPostiveDigit:(UITextField *)textField {
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inputSet = [NSCharacterSet characterSetWithCharactersInString:textField.text];
    BOOL isNum = [alphaNums isSupersetOfSet:inputSet];
    BOOL isPositive = [textField.text intValue] > 0;
    
    return isNum && isPositive;
}

#pragma mark IBAction Methods
- (IBAction)addVideosButtonTouched:(id)sender {
    if (self.durationTextField.isFirstResponder) {
        [self.durationTextField resignFirstResponder];
    }
    
    if ([self isTextFieldPostiveDigit:self.durationTextField] == NO) {
        //TODO: Notify user what's wrong (dialog?)
        NSLog(@"Add Videos pressed without positive number in text field");
        return;
    }
    
    NSLog(@"Starting video generation");    
    
    [self markVideoOperationAsStarting];
    [FeatureAPI.singleFeatureAPI addVideoWithDuration:self.durationTextField.text.intValue withCompletionBlock:^(NSError *error) {
        NSLog(@"Adding videos complete!");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.doneLabel.hidden = NO;
            [self markVideoOperationAsEnded];
        });
    }];
}

#pragma mark FeatureAPIDelegate Methods
-(void)statusUpdateFromModelWithInfoObject:(id)infoObject error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self markVideoOperationAsEnded];
        } else {
            NSNumber *progressNumber = (NSNumber *)infoObject;
            [self.progressBarView setProgress:[progressNumber floatValue] animated:YES];
        }
    });
}

#pragma mark UITextFieldDelegate Methods
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.doneLabel.hidden = YES;
    [self.progressBarView setProgress:0.0f animated:NO];
    
    self.textFieldWithFocus = textField;
    [self.view addGestureRecognizer:self.tap];
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.textFieldWithFocus) {
        self.textFieldWithFocus = nil;
        [self.view removeGestureRecognizer:self.tap];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return [self isTextFieldPostiveDigit:textField];
}

#pragma mark Lazy Loaded Properties
-(FeatureAPI *)featureAPI {
    if (_featureAPI == nil) {
        _featureAPI = FeatureAPI.singleFeatureAPI;
    }
    return _featureAPI;
}

@end
