//
//  TinyGLTFSCN.h
//  glTF-quicklook
//
//  Created by Klochkov Anton on 12/06/2019.
//  Copyright © 2019 Klochkov Anton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TinyGLTFSCN : NSObject

- (BOOL) loadModel: (NSURL *) modelURL;

@property (nonatomic, readonly) NSArray *scenes;
@property (nonatomic, readonly) NSDictionary *animations;

@end

NS_ASSUME_NONNULL_END
