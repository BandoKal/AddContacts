//
//  AddVideosModel.m
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import "AddVideosModel.h"
#import "ImageManager.h"
#import <AVFoundation/AVFoundation.h>

@implementation AddVideosModel

// singleton accessor
+ (instancetype)videoManager {
    static AddVideosModel *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance =[[AddVideosModel alloc] init];
    });
    return sharedInstance;
}

- (void)addRandomVideoForDuration:(int)duration imageManager:(ImageManager *)imageManager {
    CGSize size = CGSizeMake(1080, 1920);
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:[self tempVideoPath]]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    // Start a session:
    if ([videoWriter startWriting]) {
        NSLog(@"Video writing started successfully.");
    } else {
        NSLog(@"Video writing NOT started successfully.");
    }
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // Write samples:
    int32_t framesPerSecond = 60;
    int numberOfDifferentImages = 1;
    
    int numberOfFrames = framesPerSecond * duration;
    int numberOfTimesToUseEachImage = numberOfFrames / numberOfDifferentImages;
    
    for (int i=0; i<numberOfDifferentImages; i++) {
        @autoreleasepool {
            CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[imageManager generateRandomImage].CGImage size:size];
            
            for (int j=0; j<numberOfTimesToUseEachImage; j++) {
                while (!adaptor.assetWriterInput.readyForMoreMediaData) {
                    // Waiting for assetWriterInput to get readyForMoreMediaData
                }
                
                if ((i == 0) && (j == 0)) {
                    if ([adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero]) {
                    } else {
                        NSLog(@"Video append failed: 0");
                        break;
                    }
                } else {
                    if ([adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake((i*numberOfTimesToUseEachImage)+j, framesPerSecond)]) {
                    } else {
                        NSLog(@"Video append failed; i: %i, j: %i", i, j);
                        break;
                    }
                }
            }
            
            if (buffer) {
                CVBufferRelease(buffer);
            }
        }
    }
    
    // Finish the session:
    [writerInput markAsFinished];
    [videoWriter endSessionAtSourceTime:CMTimeMake(numberOfFrames, framesPerSecond)];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Video writing finished.");
    }];
}

- (void)createMovieUsingImages:(NSArray *)images atPath:(NSString *)path size:(CGSize)size duration:(int)duration {
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    // Start a session:
    if ([videoWriter startWriting]) {
        NSLog(@"Video writing started successfully.");
    } else {
        NSLog(@"Video writing NOT started successfully.");
    }
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // Write samples:
    int currentTimeSlice = 0;
    int lengthOfTimeSlice = duration / images.count;
    for (UIImage *image in images) {
        CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage size:size];
        
        for (int i=0; i<lengthOfTimeSlice; i++) {
            while (!adaptor.assetWriterInput.readyForMoreMediaData) {
                // Waiting for assetWriterInput to get readyForMoreMediaData
            }
            
            if ((currentTimeSlice == 0) && (i == 0)) {
                [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
            } else {
                [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake((currentTimeSlice * lengthOfTimeSlice) + i, 1)];
            }
        }
        
        currentTimeSlice++;
        if (buffer) {
            CVBufferRelease(buffer);
        }
    }
    
    // Finish the session:
    [writerInput markAsFinished];
    [videoWriter endSessionAtSourceTime:CMTimeMake(duration, 1)];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Video writing finished.");
    }];
}

static int counter = 0;
static int onePieceDuration = 100;
-(void)writeImageAsMovie:(UIImage*)image toPath:(NSString*)path size:(CGSize)size duration:(int)duration {
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    //Start a session:
    if ([videoWriter startWriting]) {
        NSLog(@"Video writing started successfully.");
    }
    [videoWriter startSessionAtSourceTime:CMTimeMake(onePieceDuration * counter, 2)];
    counter++;
    
    //Write samples:
    CVPixelBufferRef buffer = [self pixelBufferFromCGImage:image.CGImage size:size];
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(duration-1, 2)];
    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter endSessionAtSourceTime:CMTimeMake(duration, 2)];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Finished writing.");
    }];
}

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

-(void)addRandomVideoForDuration:(int)duration images:(NSArray*)imagesArray {
    [self createMovieUsingImages:imagesArray atPath:[self tempVideoPath] size:CGSizeMake(320.0f, 480.f) duration:duration];
}

- (void)cleanupTempVideos {
    [[NSFileManager defaultManager] removeItemAtPath:[self tempVideoPath] error:nil];
}

- (NSString *)tempVideoPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [paths objectAtIndex:0];
    
    NSString *filePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"myMovie.mov"]];
    
    return filePath;
}

@end
