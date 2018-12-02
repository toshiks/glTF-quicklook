//
//  GLTFErrorChecker.hpp
//  glTF-qucklook
//
//  Created by Klochkov Anton on 02/12/2018.
//  Copyright © 2018 Klochkov Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GR : NSObject
+ (bool) isGoodGLTFByName:(const char*) name;
@end

NS_ASSUME_NONNULL_END


