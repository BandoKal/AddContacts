//
//  ImageManager.m
//  AddContacts
//
//  Created by Locke, Jamaal on 5/15/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "ImageManager.h"
#import "ALAssetsLibrary+LibraryHelper.h"

NSString *const BCGimageManipulationErrorDomain = @"imageManipulationErrorDomain";
NSUInteger const BCGsecondsToWaitImportingOneImage = 3;

@interface ImageManager ()

@property (nonatomic, strong) ALAssetsLibrary *alAssetsLibrary;
@property (nonatomic, strong) NSMutableArray *delegates;

@end

@implementation ImageManager

#pragma mark External Interface
-(instancetype)initWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary delegate:(id<ImageManagerDelegate>)delegateToAdd {
    self = [super init];
    if (self) {
        if (assetsLibrary == nil) {
            NSLog(@"nil ALAssetsLibrary used to create ImageManager");
            return nil;
        }
        _alAssetsLibrary = assetsLibrary;
        
        _delegates = [NSMutableArray array];
        if (delegateToAdd != nil) {
            [_delegates addObject:delegateToAdd];
        }
    }
    return self;
}

-(void)addImages:(NSArray *)imagesToAdd toAlbum:(NSString *)album {
    if (imagesToAdd == nil) {
        NSLog(@"Aborting adding images because nil array of images received");
        [self notifyDelegatesOfCompleteFailureWithError:[self createErrorWithDomain:BCGimageManipulationErrorDomain
                                                                               code:BCGimageManipulationErrorCode_InvalidImageAdded
                                                                            message:@"nil array of images received"]];
        return;
    }
    
    __block BOOL errorOccurred = NO;
    for (int i=0; i<imagesToAdd.count; i++) {
        dispatch_semaphore_t importingAnImage = dispatch_semaphore_create(0);
        
        if ([[imagesToAdd objectAtIndex:i] isKindOfClass:[UIImage class]] == YES) {
            [self.alAssetsLibrary saveImage:[imagesToAdd objectAtIndex:i] toAlbum:album withCompletionBlock:^(NSError *error) {
                if (error != nil) {
                    [self notifyDelegatesOfPartialFailureWithError:error onObject:[imagesToAdd objectAtIndex:i]];
                    errorOccurred = YES;
                } else {
                    [self notifyDelegatesOfCurrentProgress:i+1 ofTotal:imagesToAdd.count+1];
                }
                
                dispatch_semaphore_signal(importingAnImage);
            }];
        } else {
            NSLog(@"Aborting adding images because a non-UIImage was received: %@", [imagesToAdd objectAtIndex:i]);
            NSError *notAnImageError = [self createErrorWithDomain:BCGimageManipulationErrorDomain
                                                              code:BCGimageManipulationErrorCode_InvalidImageAdded
                                                           message:@"received object was not a UIImage"];
            [self notifyDelegatesOfPartialFailureWithError:notAnImageError onObject:[imagesToAdd objectAtIndex:i]];
            errorOccurred = YES;
        }
        
        long semaphoreWaitReturnValue = dispatch_semaphore_wait(importingAnImage, BCGsecondsToWaitImportingOneImage * NSEC_PER_SEC);
        
        if (semaphoreWaitReturnValue != 0) {
            NSLog(@"timeout occurred waiting to import image to ALAssetsLibrary");
            NSError *timeoutError = [self createErrorWithDomain:BCGimageManipulationErrorDomain
                                                           code:BCGImageManipulationErrorCode_TimeoutDuringImageImport
                                                        message:@"timeout importing image into ALAssetsLibrary"];
            [self notifyDelegatesOfPartialFailureWithError:timeoutError onObject:[imagesToAdd objectAtIndex:i]];
            errorOccurred = YES;
        }
        
        if (errorOccurred) {
            // Delegate notification has been handled at point of error; just stop trying to add more images
            break;
        }
    }
    
    if (errorOccurred == NO) {
        [self notifyDelegatesOfSuccessfulCompletion];
    }
}

-(UIImage *)generateRandomImage {
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

#pragma mark Internal Helpers
-(NSError *)createErrorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message {
    return [[NSError alloc] initWithDomain:domain code:code userInfo:@{ @"errorMessage" : message}];
}

#pragma mark Delegate Notifications
-(void)notifyDelegatesOfCompleteFailureWithError:(NSError *)error {
    for (id<ImageManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imageOperationFailedCompletelyWithError:)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate imageOperationFailedCompletelyWithError:error];
            });
        }
    }
}

-(void)notifyDelegatesOfCurrentProgress:(NSUInteger)currentProgress ofTotal:(NSUInteger)totalToAdd {
    for (id<ImageManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(currentProgress:ofTotal:)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate currentProgress:currentProgress ofTotal:totalToAdd];
            });
        }
    }
}

-(void)notifyDelegatesOfPartialFailureWithError:(NSError *)error onObject:(id)failedObject {
    for (id<ImageManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imageOperationFailedPartiallyWithError:onObject:)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate imageOperationFailedPartiallyWithError:error onObject:failedObject];
            });
        }
    }
}

-(void)notifyDelegatesOfSuccessfulCompletion {
    for (id<ImageManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(imageOperationCompletedSuccessfully)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate imageOperationCompletedSuccessfully];
            });
        }
    }
}

@end
