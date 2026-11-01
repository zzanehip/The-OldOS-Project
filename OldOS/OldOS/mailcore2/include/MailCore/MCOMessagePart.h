//
//  MessagePart.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/22/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOMESSAGEPART_H

#define MAILCORE_MCOMESSAGEPART_H

#import <MailCore/MCOAbstractMessagePart.h>

/** Message part parsed from RFC 822 message data. */

@interface MCOMessagePart : MCOAbstractMessagePart <NSCopying>

@end

#endif
