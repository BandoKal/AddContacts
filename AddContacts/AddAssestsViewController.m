//
//  AddAssestsViewController.m
//  AddContacts
//
//  Created by Jason Bandy on 3/11/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "AddAssestsViewController.h"
#import "AppDelegate.h"
#import "ALAsset+EditableAsset.h"
#import "ALAssetsLibrary+LibraryHelper.h"

static NSString *const imageName = @"yoda";

@interface AddAssestsViewController (){
    int imageCounter;
    BOOL isAddingImages, isRemovingImages;
}
@property (strong, nonatomic) IBOutlet UIImageView *imageViewToAdd;
@property (strong, nonatomic) IBOutlet UITextView *imageInfoView;
@property (strong, nonatomic) IBOutlet UITextField *quantityTextField;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) IBOutlet UILabel *doneLabel;
@property (strong, nonatomic) ALAssetsGroup *groupToSave;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) int numImages;
@end

@implementation AddAssestsViewController

#pragma mark View Life Cycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageViewToAdd.image = [self imageToAdd];
    self.assetsLibrary = [[ALAssetsLibrary alloc]init];
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    self.quantityTextField.delegate = self;
    isAddingImages = NO;
    isRemovingImages = NO;
    
}

#pragma mark Private Methods
-(UIImage *)imageToAdd{
    return [UIImage imageNamed:imageName];
}

-(void)addImagesToAssets {
    self.numImages = self.quantityTextField.text.intValue;
    if (imageCounter == self.numImages) {
        [self.progressBarView setProgress:0.0f animated:NO];
        self.quantityTextField.text = @"";
        self.doneLabel.hidden = NO;
        return;
    }
    [self.assetsLibrary saveImage:[self imageToAdd] toAlbum:@"Test Photos!" withCompletionBlock:^( NSError *error) {
            if (error) {
                // report the error
                NSLog(@"Error in adding Image... %@", error.localizedDescription);
                imageCounter--;
            }else{
                //report success
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = (float)(imageCounter)/(float)self.numImages;
                    [self.progressBarView setProgress:progress animated:YES];
                });
                imageCounter++;
                [self addImagesToAssets];
            }
        }];
    
}

#pragma mark - Utilities

-(BOOL)isTextFieldPostiveDigit:(UITextField*)textField{
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inputSet = [NSCharacterSet characterSetWithCharactersInString:textField.text];
    BOOL isNum = [alphaNums isSupersetOfSet:inputSet];
    BOOL isPositive = [textField.text intValue] > 0;
    return isNum && isPositive;
}

#pragma mark IBAction Methods
- (IBAction)userTouchedAddImagesWithSender:(UIButton *)sender {
    if (self.quantityTextField.isFirstResponder) {
        [self.quantityTextField resignFirstResponder];
    }
    self.doneLabel.hidden = YES;
    self.progressBarView.progressTintColor = [UIColor greenColor];
    imageCounter = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self addImagesToAssets];
    });
}


#pragma mark UITextFieldDelegate Methods
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.doneLabel.hidden = YES;
    [self.progressBarView setProgress:0.0f animated:NO];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    self.numImages = textField.text.intValue;
    return [self isTextFieldPostiveDigit:textField];
}

@end
