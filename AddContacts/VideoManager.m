//
//  VideoManager.m
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "VideoManager.h"

#import "ImageManager.h"
#import "UIDevice-Hardware.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

NSString *const BCGvideoManipulationErrorDomain = @"videoManipulationErrorDomain";

@interface VideoManager () {
    CVPixelBufferRef buffer;
}

@property (nonatomic, strong) ALAssetsLibrary *alAssetsLibrary;
@property (nonatomic, strong) NSMutableArray *delegates;

@property (weak, nonatomic) ImageManager *imageManager;
@property (strong, nonatomic) AVAssetWriter *videoWriter;
@property (assign) BOOL videoWriterCompleted;

@end

@implementation VideoManager

#pragma mark External Interface
-(instancetype)initWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary delegate:(id<VideoManagerDelegate>)delegateToAdd {
    self = [super init];
    if (self) {
        if (assetsLibrary == nil) {
            NSLog(@"nil ALAssetsLibrary used to create VideoManager");
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

-(void)addRandomVideoForDuration:(int)duration imageManager:(ImageManager *)imageManager {
    CGSize size = CGSizeMake(1080, 1920);
    int32_t framesPerSecond = 60;
    int numberOfDifferentImages = 1;
    int portionDuration = 10;
    
    // Memory pressure causes a crash with even 10sec portion duration on these devices
    BOOL deviceIsIphone4 = [UIDevice.currentDevice.platformString isEqualToString:IPHONE_4_NAMESTRING];
    BOOL deviceIsIphone4s = [UIDevice.currentDevice.platformString isEqualToString:IPHONE_4S_NAMESTRING];
    
    if (deviceIsIphone4 || deviceIsIphone4s) {
        portionDuration = 5;
    }
    
    // Force duration to be an even multiple of portionDuration to avoid having one portion of a different duration than the others
    if ((duration % portionDuration) > 0) {
        duration += (portionDuration - (duration % portionDuration));
    }
    
    int numberOfFrames = framesPerSecond * duration;
    int numberOfPortions = duration / portionDuration;
    int framesPerPortion = numberOfFrames / numberOfPortions;
    
    self.imageManager = imageManager;
    
    
    NSError *error = nil;
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self tempVideoPath]]
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
    NSParameterAssert(self.videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([self.videoWriter canAddInput:writerInput]);
    [self.videoWriter addInput:writerInput];
    
    if ([self.videoWriter startWriting]) {
        NSLog(@"Video writing started successfully.");
    } else {
        NSLog(@"Video writing NOT started successfully.");
        [self notifyDelegatesOfCompleteFailureWithError:[self createErrorWithDomain:BCGvideoManipulationErrorDomain
                                                                               code:BCGVideoManipulationErrorCode_FailedStartingVideoWritingSession
                                                                            message:@"Starting video writer failed"]];
        return;
    }
    
    // Start a session:
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    for (int i=0; i<numberOfPortions; i++) {
        NSLog(@"Writing video portion #%i", i);
        // Try to append video portion; if it fails, notify of error and quit
        if ([self createVideoPortionWithSize:size
                         framesBeforeNow:i*framesPerPortion
                                 adaptor:adaptor
                         framesPerSecond:framesPerSecond
                 numberOfDifferentImages:numberOfDifferentImages
                              numberOfFrames:framesPerPortion] == NO) {
            NSString *errorMessage = [NSString stringWithFormat:@"Appending Pixel Buffer #%i Failed", i];
            [self notifyDelegatesOfCompleteFailureWithError:[self createErrorWithDomain:BCGvideoManipulationErrorDomain
                                                                                   code:BCGVideoManipulationErrorCode_FailedAppendingPixelBuffer
                                                                                message:errorMessage]];
            return;
        }
        // Use i instead of i+1 so there is room in the progress for the import to assets library at the end
        [self notifyDelegatesOfCurrentProgress:i ofTotal:numberOfPortions];
    }
    
    // Finish the session:
    [writerInput markAsFinished];
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Video writing finished.");
        
        // Import generated video into the assets library
        NSURL *fileURL = [NSURL fileURLWithPath:[self tempVideoPath]];
        
        [self.alAssetsLibrary writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"Error importing video into AssetsLibrary: %@",error.localizedDescription);
                [self notifyDelegatesOfCompleteFailureWithError:error];
            } else {
                [self notifyDelegatesOfCurrentProgress:1 ofTotal:1];
                [self notifyDelegatesOfSuccessfulCompletion];
            }
            [self cleanupTempVideos];
        }];
    }];
}

-(void)cleanupTempVideos {
    [NSFileManager.defaultManager removeItemAtPath:[self tempVideoPath] error:nil];
}

-(NSString *)tempVideoPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString *filePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"myMovie.mov"]];
    
    return filePath;
}

#pragma mark Internal Helpers
-(NSError *)createErrorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message {
    return [[NSError alloc] initWithDomain:domain code:code userInfo:@{ @"errorMessage" : message }];
}

/// Returns YES if video portion is added successfully. Otherwise, returns NO.
-(BOOL)createVideoPortionWithSize:(CGSize)size
                   framesBeforeNow:(int)framesBeforeNow
                           adaptor:(AVAssetWriterInputPixelBufferAdaptor *)adaptor
                   framesPerSecond:(int)framesPerSecond
           numberOfDifferentImages:(int)numberOfDifferentImages
                    numberOfFrames:(int)numberOfFrames {
    
    BOOL portionAddedSuccessfully = YES;
    // Write samples:
    int numberOfTimesToUseEachImage = numberOfFrames / numberOfDifferentImages;
    
    for (int i=0; i<numberOfDifferentImages; i++) {
        // The imageManager's generateRandomImage creates and returns an object that is released by this autoreleasepool
        // The adaptor's appendPixelBuffer:withPresentationTime: calls create a copy of the buffer in virtual memory. That memory is released by this autoreleasepool
        @autoreleasepool {
            if (buffer == nil) {
                buffer = [self pixelBufferFromCGImage:[self.imageManager generateRandomImage].CGImage size:size];
            }
            
            for (int j=0; j<numberOfTimesToUseEachImage; j++) {
//                NSLog(@"Using image for time #%i", j);
                while (!adaptor.assetWriterInput.readyForMoreMediaData) {
                    // Waiting for assetWriterInput to get readyForMoreMediaData
                }
                
                if ((i == 0) && (j == 0) && (framesBeforeNow == 0)) {
                    if ([adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero]) {
                    } else {
                        NSLog(@"Video append failed: 0");
                        portionAddedSuccessfully = NO;
                        break;
                    }
                } else {
                    if ([adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(framesBeforeNow+(i*numberOfTimesToUseEachImage)+j, framesPerSecond)]) {
                    } else {
                        NSLog(@"Video append failed; i: %i, j: %i", i, j);
                        portionAddedSuccessfully = NO;
                        break;
                    }
                }
            }
            
            if (buffer) {
                CVBufferRelease(buffer);
                buffer = nil;
            }
        }
    }
    
    return portionAddedSuccessfully;
}

//- (void)createMovieUsingImages:(NSArray *)images atPath:(NSString *)path size:(CGSize)size duration:(int)duration {
//    NSError *error = nil;
//    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
//                                                           fileType:AVFileTypeQuickTimeMovie
//                                                              error:&error];
//    NSParameterAssert(videoWriter);
//    
//    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                   AVVideoCodecH264, AVVideoCodecKey,
//                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
//                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
//                                   nil];
//    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
//                                                                         outputSettings:videoSettings];
//    
//    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
//                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
//                                                     sourcePixelBufferAttributes:nil];
//    NSParameterAssert(writerInput);
//    NSParameterAssert([videoWriter canAddInput:writerInput]);
//    [videoWriter addInput:writerInput];
//    
//    // Start a session:
//    if ([videoWriter startWriting]) {
//        NSLog(@"Video writing started successfully.");
//    } else {
//        NSLog(@"Video writing NOT started successfully.");
//    }
//    [videoWriter startSessionAtSourceTime:kCMTimeZero];
//    
//    // Write samples:
//    int currentTimeSlice = 0;
//    int lengthOfTimeSlice = duration / images.count;
//    for (UIImage *image in images) {
//        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage size:size];
//        
//        for (int i=0; i<lengthOfTimeSlice; i++) {
//            while (!adaptor.assetWriterInput.readyForMoreMediaData) {
//                // Waiting for assetWriterInput to get readyForMoreMediaData
//            }
//            
//            if ((currentTimeSlice == 0) && (i == 0)) {
//                [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
//            } else {
//                [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake((currentTimeSlice * lengthOfTimeSlice) + i, 1)];
//            }
//        }
//        
//        currentTimeSlice++;
//        if (buffer) {
//            CVBufferRelease(buffer);
//        }
//    }
//    
//    // Finish the session:
//    [writerInput markAsFinished];
//    [videoWriter endSessionAtSourceTime:CMTimeMake(duration, 1)];
//    [videoWriter finishWritingWithCompletionHandler:^{
//        NSLog(@"Video writing finished.");
//    }];
//}

//static int counter = 0;
//static int onePieceDuration = 100;
//-(void)writeImageAsMovie:(UIImage*)image toPath:(NSString*)path size:(CGSize)size duration:(int)duration {
//    NSError *error = nil;
//    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
//                                                           fileType:AVFileTypeQuickTimeMovie
//                                                              error:&error];
//    NSParameterAssert(videoWriter);
//    
//    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                   AVVideoCodecH264, AVVideoCodecKey,
//                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
//                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
//                                   nil];
//    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
//                                                                         outputSettings:videoSettings];
//    
//    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
//                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
//                                                     sourcePixelBufferAttributes:nil];
//    NSParameterAssert(writerInput);
//    NSParameterAssert([videoWriter canAddInput:writerInput]);
//    [videoWriter addInput:writerInput];
//    
//    //Start a session:
//    if ([videoWriter startWriting]) {
//        NSLog(@"Video writing started successfully.");
//    }
//    [videoWriter startSessionAtSourceTime:CMTimeMake(onePieceDuration * counter, 2)];
//    counter++;
//    
//    //Write samples:
//    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage size:size];
//    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
//    [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(duration-1, 2)];
//    
//    //Finish the session:
//    [writerInput markAsFinished];
//    [videoWriter endSessionAtSourceTime:CMTimeMake(duration, 2)];
//    [videoWriter finishWritingWithCompletionHandler:^{
//        NSLog(@"Finished writing.");
//    }];
//}

-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 bitmapInfo);
    NSParameterAssert(context);
    
//    CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
//    CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

//-(void)addRandomVideoForFileSize:(NSUInteger)fileSize images:(NSArray*)imagesArray {
//    for (UIImage *image in imagesArray) {
//        
//        [self writeImageAsMovie:image toPath:[self tempVideoPath] size:CGSizeMake(0.0f, 0.0f) duration:30.0f];
//    }
//}

//-(void)addRandomVideoForDuration:(int)duration images:(NSArray*)imagesArray {
//    [self createMovieUsingImages:imagesArray atPath:[self tempVideoPath] size:CGSizeMake(320.0f, 480.f) duration:duration];
//}


#pragma mark Delegate Notifications
-(void)notifyDelegatesOfCompleteFailureWithError:(NSError *)error {
    for (id<VideoManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(videoOperationFailedCompletelyWithError:)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate videoOperationFailedCompletelyWithError:error];
            });
        }
    }
}

-(void)notifyDelegatesOfCurrentProgress:(NSUInteger)currentProgress ofTotal:(NSUInteger)totalToAdd {
    for (id<VideoManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(currentVideoProgress:ofTotal:)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate currentVideoProgress:currentProgress ofTotal:totalToAdd];
            });
        }
    }
}

-(void)notifyDelegatesOfSuccessfulCompletion {
    for (id<VideoManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(videoOperationCompletedSuccessfully)]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [delegate videoOperationCompletedSuccessfully];
            });
        }
    }
}

@end
