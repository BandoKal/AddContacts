//
//  AddVideosModel.h
//  AddContacts
//
//  Created by Jason Bandy on 5/7/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@interface AddVideosModel : NSObject

+(AddVideosModel*)videoManager;

-(void)addRandomVideoForFileSize:(NSUInteger)fileSize images:(NSArray*)imagesArray;
-(void)addRandomVideoForDuration:(NSUInteger)duration images:(NSArray*)imagesArray;

@end
