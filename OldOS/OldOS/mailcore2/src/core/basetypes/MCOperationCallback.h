#ifndef MAILCORE_MCOPERATIONCALLBACK_H

#define MAILCORE_MCOPERATIONCALLBACK_H

#include <MailCore/MCUtils.h>

#ifdef __cplusplus

namespace mailcore {
    
    class Operation;
    
    class MAILCORE_EXPORT OperationCallback {
    public:
        virtual void operationFinished(Operation * op) {}
    };
    
}

#endif

#endif
