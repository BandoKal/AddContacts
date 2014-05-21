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

@end

@implementation AddVideosViewController

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
    // Do any additional setup after loading the view.
    [FeatureAPI.singleFeatureAPI addVideoWithDuration:1000 withCompletionBlock:^(NSError *error) {
        if (error) {
            NSLog(@"error");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
