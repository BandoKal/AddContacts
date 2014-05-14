//
//  FeatureAPI.m
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "FeatureAPI.h"

#import "AddContactsModel.h"
#import "AddPhotosModel.h"
#import "AddVideosModel.h"

@interface FeatureAPI()

@end



@implementation FeatureAPI

#pragma mark - Public Methods


// singleton accessor
+(FeatureAPI*)singleFeatureAPI {
    static FeatureAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance =[[FeatureAPI alloc]init];
    });
    return sharedInstance;
}

+(ALAssetsLibrary*)singleAlAssetsLibrary {
    static ALAssetsLibrary *sharedLibrary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLibrary = [[ALAssetsLibrary alloc]init];
    });
    return sharedLibrary;
}


#pragma mark Contacts Feature Set
-(BOOL)requestAccessToABBook {
    return NO;
}

-(void)addContacts:(NSArray*)contactsToAdd withCompletionBlock:(APICompletionBlock)completionBlock {
    
}
-(void)removeAllContactsWithCompletionBlock:(APICompletionBlock)completionBlock{
    
}

#pragma mark Photo Feature Set
-(void)addPhotos:(NSArray*) imagesToAdd toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock{
    if (imagesToAdd == Nil &&
        [[imagesToAdd firstObject]isKindOfClass:[UIImage class]] == NO) {
        NSLog(@"Aborting adding of photos because empty array passed or array of non image objects passed");
        NSError *error = [[NSError alloc]initWithDomain:Nil code:100 userInfo:@{NSLocalizedDescriptionKey: @"Aborting adding of photos because empty array passed or array of non image objects passed"}];
        completionBlock(error);
    }
    
    for (int i = 0; i< imagesToAdd.count; i++){
        UIImage *imageObject =[imagesToAdd objectAtIndex:i];
        [FeatureAPI.singleAlAssetsLibrary saveImage:imageObject toAlbum:albumName withCompletionBlock:^(NSError *error){
            float currentProgress = (float)i/(float)imagesToAdd.count;
            [self.delegate statusUpdateFromModelWithInfoObject:currentProgress error:error];
        }];
    }
}


-(void)addRandomPhotosWithCount:(NSUInteger*)imageCount toAlbumName:(NSString*)albumName withCompletionBlock:(APICompletionBlock)completionBlock{
    NSMutableArray *imagesToAdd = [[NSMutableArray alloc]init];
    for (int i = 0; i < (int)imageCount; i++) {
        
        [imagesToAdd addObject:[self createRandomImage]];
    }
    [self addPhotos:imagesToAdd toAlbumName:albumName withCompletionBlock:completionBlock];
}

#pragma mark - Private Methods

-(UIImage*)createRandomImage {
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
}

@end
