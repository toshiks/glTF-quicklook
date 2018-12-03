//
//  ThumbnailGenerator.h
//  glTF-qucklook
//
//  Created by Klochkov Anton on 03/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThumbnailGenerator : NSObject

+ (NSImage *) thumbnailImageByURL:(CFURLRef)url rect:(NSRect)rect;

@end

NS_ASSUME_NONNULL_END
