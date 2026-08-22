//
//  MCOAddress+Private.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/11/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCOADDRESS_PRIVATE_H

#define MAILCORE_MCOADDRESS_PRIVATE_H

#ifdef __cplusplus
namespace mailcore {
    class Address;
}

@interface MCOAddress (Private)

- (instancetype) initWithMCAddress:(mailcore::Address *)address;
+ (MCOAddress *) addressWithMCAddress:(mailcore::Address *)address;

@end
#endif

#endif
