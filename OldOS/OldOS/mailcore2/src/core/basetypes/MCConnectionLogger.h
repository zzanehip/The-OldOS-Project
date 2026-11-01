//
//  MCConnectionLogger.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 6/24/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_CONNECTION_LOGGER_H

#define MAILCORE_CONNECTION_LOGGER_H

#include <stdlib.h>

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class Data;
    
    enum ConnectionLogType {
        // Received data
        ConnectionLogTypeReceived,
        // Sent data
        ConnectionLogTypeSent,
        // Sent private data
        ConnectionLogTypeSentPrivate,
        // Parse error
        ConnectionLogTypeErrorParse,
        // Error while receiving data - log() is called with a NULL buffer.
        ConnectionLogTypeErrorReceived,
        // Error while sending data - log() is called with a NULL buffer.
        ConnectionLogTypeErrorSent,
    };
    
    class MAILCORE_EXPORT ConnectionLogger {
    public:
        virtual void log(void * sender, ConnectionLogType logType, Data * buffer) {}
    };
    
}

#endif

#endif
