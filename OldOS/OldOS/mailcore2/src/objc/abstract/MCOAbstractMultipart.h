//
//  MCOAbstractMultipart.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/10/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOABSTRACTMULTIPART_H

#define MAILCORE_MCOABSTRACTMULTIPART_H

#import <Foundation/Foundation.h>
#import <MailCore/MCOAbstractPart.h>

@interface MCOAbstractMultipart : MCOAbstractPart

/** Returns the subparts of that multipart.*/
@property (nonatomic, copy) NSArray<MCOAbstractPart *> *parts;

@end

#endif
