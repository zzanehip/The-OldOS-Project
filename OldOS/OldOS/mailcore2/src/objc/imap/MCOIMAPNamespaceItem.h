//
//  MCOIMAPNamespaceItem.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/23/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOIMAPNAMESPACEITEM_H

#define MAILCORE_MCOIMAPNAMESPACEITEM_H

/** Represents a namespace item */

#import <Foundation/Foundation.h>

@interface MCOIMAPNamespaceItem : NSObject <NSCopying>

/** This is the prefix for this namespace item */
@property (nonatomic, copy) NSString * prefix;

/** This is the delimiter of the path for this namespace item */
@property (nonatomic, assign) char delimiter;

/** Returns folder path for given path components in the context of this namespace item */
- (NSString *) pathForComponents:(NSArray<NSString *> *)components;

/** Returns components for the given path in the context of this namespace */
- (NSArray<NSString *> *) componentsForPath:(NSString *)path;

/** Returns YES if the namespace contains this folder path */
- (BOOL) containsFolder:(NSString *)folder;

@end

#endif
