//
//  ALAssetRepresentationMock.m
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import "ALAssetRepresentationMock.h"

@implementation ALAssetRepresentationMock

-(NSURL *) url {
    return self.assetURL;
}

-(NSString *) filename {
    return self.assetFileName;
}

-(long long) size {
    return self.assetSize;
}

-(NSString *)UTI {
    return self.assetUTI;
}

- (NSUInteger)getBytes:(uint8_t *)buffer fromOffset:(long long)offset length:(NSUInteger)length error:(NSError **)error {
    [self.bufferData getBytes:buffer range:NSMakeRange((NSUInteger)offset, length)];
    *error = self.error;
    return length;
}

@end
