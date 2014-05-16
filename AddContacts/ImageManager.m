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
NSUInteger const BCGsecondsToWaitImportingOneImage = 10;

@interface ImageManager ()

@property (nonatomic, strong) ALAssetsLibrary *alAssetsLibrary;
@property (nonatomic, strong) NSMutableArray *delegates;
@property (nonatomic, strong) UIImage *baseImage;

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
        _baseImage = [UIImage imageNamed:@"base_image.jpg"];
        
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
    
    __block NSError *errorThatOccurred = nil;
    for (int i=0; i<imagesToAdd.count; i++) {
        UIImage *currentImage = [imagesToAdd objectAtIndex:i];
        
        dispatch_semaphore_t addingOneImage = dispatch_semaphore_create(0);
        [self addImage:currentImage toAlbum:album withCompletionBlock:^(NSError *error) {
            errorThatOccurred = error;
            dispatch_semaphore_signal(addingOneImage);
        }];
        // This semaphpore waits forever, but the one inside addImage does not wait forever
        dispatch_semaphore_wait(addingOneImage, DISPATCH_TIME_FOREVER);
        
        if (errorThatOccurred != nil) {
            [self notifyDelegatesOfPartialFailureWithError:errorThatOccurred onObject:currentImage];
            break;
        }
        
        [self notifyDelegatesOfCurrentProgress:i+1 ofTotal:imagesToAdd.count];
    }
    
    if (errorThatOccurred == nil) {
        [self notifyDelegatesOfSuccessfulCompletion];
    }
}

-(void)addRandomImagesWithCount:(NSUInteger)numberOfImages toAlbum:(NSString *)album {
    NSMutableArray *randomValues = [self arrayOfRandomFloatsWithCount:5];
    __block NSError *errorThatOccurred = nil;
    
    for (int i=0; i<numberOfImages; i++) {
        [randomValues replaceObjectAtIndex:i%5 withObject:[self generateRandomFloat]];
        // The (UIImage *) returned by [self generateRandomImageUsingValues:startingMarker:] needs to be released each iteration
        @autoreleasepool {
            UIImage *currentImage = [self generateRandomImageUsingValues:randomValues startingMarker:i%5];
            
            dispatch_semaphore_t addingOneImage = dispatch_semaphore_create(0);
            [self addImage:currentImage toAlbum:album withCompletionBlock:^(NSError *error) {
                errorThatOccurred = error;
                dispatch_semaphore_signal(addingOneImage);
            }];
            // This semaphpore waits forever, but the one inside addImage does not wait forever
            dispatch_semaphore_wait(addingOneImage, DISPATCH_TIME_FOREVER);
            
            if (errorThatOccurred != nil) {
                [self notifyDelegatesOfPartialFailureWithError:errorThatOccurred onObject:currentImage];
                break;
            }
        }
            
        [self notifyDelegatesOfCurrentProgress:i+1 ofTotal:numberOfImages];
    }
    
    if (errorThatOccurred == nil) {
        [self notifyDelegatesOfSuccessfulCompletion];
    }
}

-(UIImage *)generateRandomImage {
    NSMutableArray *randomValues = [self arrayOfRandomFloatsWithCount:5];
    return [self generateRandomImageUsingValues:randomValues startingMarker:0];
}

-(NSArray *)generateRandomImagesWithCount:(NSUInteger)numberOfImages {
    NSMutableArray *arrayOfImages = [NSMutableArray array];
    
    NSMutableArray *randomValues = [self arrayOfRandomFloatsWithCount:5];
    
    for (int i=0; i<numberOfImages; i++) {
        [randomValues replaceObjectAtIndex:i%5 withObject:[self generateRandomFloat]];
        // The pointer returned by [self generateRandomImageUsingValues:startingMarker:] is the memory leak. Keeping that pointer (such as adding it to the array) leads to its memory not going away until the pointer (or array holding the pointer in this case) goes away
        [arrayOfImages addObject:[self generateRandomImageUsingValues:randomValues startingMarker:i%5]];
        
        // An attempt at fixing the above mentioned memory leak
//        @autoreleasepool {
//            [self addImages:@[[self generateRandomImageUsingValues:randomValues startingMarker:i%5]] toAlbum:@"Test Images!"];
//        }
    }
    
    return arrayOfImages;
}

#pragma mark Internal Helpers
-(void)addImage:(UIImage *)image toAlbum:(NSString *)album withCompletionBlock:(SaveImageCompletion)completionBlock {
    __block NSError *errorToReturn = nil;
    dispatch_semaphore_t importingAnImage = dispatch_semaphore_create(0);
    
    if ([image isKindOfClass:[UIImage class]] == YES) {
        [self.alAssetsLibrary saveImage:image toAlbum:album withCompletionBlock:^(NSError *error) {
            if (error != nil) {
                errorToReturn = error;
            }
            
            dispatch_semaphore_signal(importingAnImage);
        }];
    } else {
        NSLog(@"Aborting adding images because a non-UIImage was received: %@", image);
        errorToReturn = [self createErrorWithDomain:BCGimageManipulationErrorDomain
                                               code:BCGimageManipulationErrorCode_InvalidImageAdded
                                            message:@"received object was not a UIImage"];
        
        dispatch_semaphore_signal(importingAnImage);
    }
    
    long semaphoreWaitReturnValue = dispatch_semaphore_wait(importingAnImage, dispatch_time(DISPATCH_TIME_NOW, BCGsecondsToWaitImportingOneImage * NSEC_PER_SEC));
    
    if (semaphoreWaitReturnValue != 0) {
        NSLog(@"timeout occurred waiting to import image to ALAssetsLibrary");
        errorToReturn = [self createErrorWithDomain:BCGimageManipulationErrorDomain
                                               code:BCGImageManipulationErrorCode_TimeoutDuringImageImport
                                            message:@"timeout importing image into ALAssetsLibrary"];
    }
    
    completionBlock(errorToReturn);
}

-(NSMutableArray *)arrayOfRandomFloatsWithCount:(NSUInteger)numberOfRandoms {
    NSMutableArray *randomArray = [NSMutableArray array];
    
    for (int i=0; i<numberOfRandoms; i++) {
        // Generate number between 0.0 and 0.999 (inclusive)
        [randomArray addObject:[self generateRandomFloat]];
    }
    
    return randomArray;
}

-(NSError *)createErrorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message {
    return [[NSError alloc] initWithDomain:domain code:code userInfo:@{ @"errorMessage" : message }];
}

-(NSNumber *)generateRandomFloat {
    return [NSNumber numberWithFloat:arc4random() % 1000 / 1000.0];
}

-(UIImage *)generateRandomImageUsingValues:(NSArray *)randomValues startingMarker:(NSUInteger)startingMarker {
    CGFloat overlayBlockWidth = 1800;
    CGFloat overlayBlockHeight = 1800;
    CGFloat imageWidth = 2448;
    CGFloat imageHeight = 3264;
    CGSize size = CGSizeMake(imageWidth, imageHeight);
    
    UIColor *randomColor = [UIColor colorWithRed:[[randomValues objectAtIndex:startingMarker] floatValue]
                                           green:[[randomValues objectAtIndex:(startingMarker+1)%5] floatValue]
                                            blue:[[randomValues objectAtIndex:(startingMarker+2)%5] floatValue]
                                           alpha:1.0];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw real image to context
    [self.baseImage drawAtPoint:CGPointZero];
    
    // Draw random square on top of real image
    CGContextSetFillColorWithColor(context, randomColor.CGColor);
    CGContextFillRect(context, CGRectMake([[randomValues objectAtIndex:(startingMarker+3)%5] floatValue]*(imageWidth/2), [[randomValues objectAtIndex:(startingMarker+4)%5] floatValue]*(imageHeight/2), overlayBlockWidth, overlayBlockHeight));
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
//    CGImageRef copyOfImage = CGBitmapContextCreateImage(context);
//    
//    UIImage *resultImage = [UIImage imageWithCGImage:copyOfImage scale:1.0 orientation:UIImageOrientationUp];
//    CGImageRelease(copyOfImage);
    UIGraphicsEndImageContext();
    
    return resultImage;
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
