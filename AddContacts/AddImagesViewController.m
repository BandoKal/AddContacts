//
//  AddImagesViewController.m
//  AddContacts
//
//  Created by Jason Bandy on 3/11/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "AddImagesViewController.h"
#import "ALAsset+EditableAsset.h"
#import "ALAssetsLibrary+LibraryHelper.h"
#import "AppDelegate.h"

static NSString *const imageName = @"yoda";
static NSString *const baseImageForRandomImages = @"base_image.jpg";

@interface AddImagesViewController (){
    BOOL _isRemovingImages;
}
@property (strong, nonatomic) IBOutlet UIImageView *imageViewToAdd;
@property (strong, nonatomic) IBOutlet UITextField *quantityTextField;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (strong, nonatomic) IBOutlet UILabel *doneLabel;
@property (weak, nonatomic) IBOutlet UISwitch *randomImageSwitch;
@property (weak, nonatomic) IBOutlet UIButton *addImagesButton;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) FeatureAPI *featureAPI;

@property (nonatomic, getter=isAddingImages) BOOL addingImages;

// Properties for hiding keyboard by touching off keyboard
@property (strong, nonatomic) UIGestureRecognizer *tap;
@property (strong, nonatomic) UITextField *textFieldWithFocus;

@end

@implementation AddImagesViewController

#pragma mark View Life Cycle Methods
-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.assetsLibrary = FeatureAPI.singleAlAssetsLibrary;
    self.appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
    self.quantityTextField.delegate = self;
    
    [self markImageOperationAsEnded];
    self.imageViewToAdd.image = [self imageToShow];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.tap.cancelsTouchesInView = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    self.featureAPI.delegate = self;
    
    if (self.isAddingImages) {
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

-(UIImage *)imageToShow {
    if (self.randomImageSwitch.on) {
        return [UIImage imageNamed:baseImageForRandomImages];
    } else {
        return [UIImage imageNamed:imageName];
    }
}

-(void)markImageOperationAsStarting {
    self.addingImages = YES;
    
    self.quantityTextField.enabled = NO;
    self.randomImageSwitch.enabled = NO;
    self.addImagesButton.enabled = NO;
    [self.addImagesButton setTitle:@"Adding Images..." forState:UIControlStateNormal];
    
    self.doneLabel.hidden = YES;
    self.progressBarView.progressTintColor = [UIColor greenColor];
    [self.progressBarView setProgress:0.0f animated:NO];
    
    UIApplication.sharedApplication.idleTimerDisabled = YES;
}

-(void)markImageOperationAsEnded {
    self.addingImages = NO;
    
    self.quantityTextField.text = @"";
    self.quantityTextField.enabled = YES;
    self.randomImageSwitch.enabled = YES;
    self.addImagesButton.enabled = YES;
    [self.addImagesButton setTitle:@"Add Images" forState:UIControlStateNormal];
    
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
-(IBAction)userTouchedAddImagesWithSender:(UIButton *)sender {
    if (self.quantityTextField.isFirstResponder) {
        [self.quantityTextField resignFirstResponder];
    }
    
    if ([self isTextFieldPostiveDigit:self.quantityTextField] == NO) {
        //TODO: Notify user what's wrong (dialog?)
        NSLog(@"Add Images pressed without positive number in text field");
        return;
    }
    
    [self markImageOperationAsStarting];
    
    if (self.randomImageSwitch.enabled == YES) {
        [FeatureAPI.singleFeatureAPI addRandomPhotosWithCount:self.quantityTextField.text.intValue toAlbumName:@"Test Photos!" withCompletionBlock:^(NSError *error) {
            NSLog(@"Adding photos complete!");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.doneLabel.hidden = NO;
                [self markImageOperationAsEnded];
            });
        }];
    } else {
        [FeatureAPI.singleFeatureAPI addPhotos:@[self.imageViewToAdd.image] toAlbumName:@"Test Photos!" withCompletionBlock:^(NSError *error) {
            NSLog(@"Adding photos complete!");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.doneLabel.hidden = NO;
                [self markImageOperationAsEnded];
            });
        }];
    }
}

- (IBAction)randomImageSwitchChanged:(id)sender {
    self.imageViewToAdd.image = [self imageToShow];
}

#pragma mark FeatureAPIDelegate Methods
-(void)statusUpdateFromModelWithInfoObject:(id)infoObject error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error != nil) {
            [self markImageOperationAsEnded];
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
