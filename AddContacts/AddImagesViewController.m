//
//  AddImagesViewController.m
//  AddContacts
//
//  Created by Jason Bandy on 3/11/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "AddImagesViewController.h"
#import "AppDelegate.h"
#import "ALAsset+EditableAsset.h"
#import "ALAssetsLibrary+LibraryHelper.h"

static NSString *const imageName = @"yoda";

@interface AddImagesViewController (){
    int imageCounter;
    BOOL isAddingImages, isRemovingImages;
}
@property (strong, nonatomic) IBOutlet UIImageView *imageViewToAdd;
@property (strong, nonatomic) IBOutlet UITextField *quantityTextField;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) IBOutlet UILabel *doneLabel;
@property (strong, nonatomic) ALAssetsGroup *groupToSave;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) int numImages;
@property (weak, nonatomic) IBOutlet UISwitch *randomImageSwitch;

// Properties for hiding keyboard by touching off keyboard
@property (strong, nonatomic) UIGestureRecognizer *tap;
@property (strong, nonatomic) UITextField *textFieldWithFocus;

@end

@implementation AddImagesViewController

#pragma mark View Life Cycle Methods
-(void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageViewToAdd.image = [self imageToAdd];
    self.assetsLibrary = [[ALAssetsLibrary alloc]init];
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
    self.quantityTextField.delegate = self;
    isAddingImages = NO;
    isRemovingImages = NO;
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.tap.cancelsTouchesInView = NO;
}

#pragma mark Private Methods
-(UIImage *)imageToAdd {
    
    if (self.randomImageSwitch.on) {
    
        CGSize size = CGSizeMake(3264, 2448);
        
        UIColor *randomColor = [UIColor colorWithRed:arc4random() % 256 / 255.0 green:arc4random() % 256 / 255.0 blue:arc4random() % 256 / 255.0 alpha:1.0];
        
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

        CGContextRef context = UIGraphicsGetCurrentContext();

        // draw to the context here
        CGContextSetFillColorWithColor(context, randomColor.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

        CGImageRef newCGImage = CGBitmapContextCreateImage(context);
        UIGraphicsEndImageContext();

        UIImage *result = [UIImage imageWithCGImage:newCGImage scale:1.0 orientation: UIImageOrientationUp];
        CGImageRelease(newCGImage);
        
        return result;

    } else {
        return [UIImage imageNamed:imageName];
    }
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
-(BOOL)isTextFieldPostiveDigit:(UITextField*)textField {
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
    self.doneLabel.hidden = YES;
    self.progressBarView.progressTintColor = [UIColor greenColor];
    imageCounter = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self addImagesToAssets];
    });
}

-(void)dismissKeyboard {
    [self.textFieldWithFocus resignFirstResponder];
}

- (IBAction)randomImageSwitchChanged:(id)sender {
    self.imageViewToAdd.image = [self imageToAdd];
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
    self.numImages = textField.text.intValue;
    return [self isTextFieldPostiveDigit:textField];
}

@end
