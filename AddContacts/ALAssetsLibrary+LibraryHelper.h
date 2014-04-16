//
//  ALAssetsLibrary+LibraryHelper.h
//  AddContacts
//
//  Created by Jason Bandy on 4/16/14.
//  Copyright (c) 2014 Jason Bandy. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
typedef void(^SaveImageCompletion)(NSError* error);

@interface ALAssetsLibrary (LibraryHelper)

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

@end
