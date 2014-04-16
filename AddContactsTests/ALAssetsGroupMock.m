//
//  ALAssetsGroupMock.m
//  CoreFramework
//
//  Created by Tulseela, Naveen on 2/28/14.
//  Copyright (c) 2014 Asurion Mobile Applications. All rights reserved.
//

#import "ALAssetsGroupMock.h"
#import "ALAssetMock.h"

NSString *const ALAssetsGroupPropertyName = @"name";

@implementation ALAssetsGroupMock

- (id)valueForProperty:(NSString *)property{
    return [self valueForKey:property];
}

- (void)enumerateAssetsUsingBlock:(ALAssetsGroupEnumerationResultsBlock)enumerationBlock {
    NSUInteger index = 0;
    for (ALAsset *asset in self.assets) {
        BOOL stop;
        enumerationBlock(asset, index++, &stop);
    }
}

-(BOOL)addAsset:(ALAsset *)asset{
    if (self.assets == nil) {
        self.assets = [[NSMutableArray alloc]init];
    }
    [self.assets addObject:asset];
    return YES;
}
@end
