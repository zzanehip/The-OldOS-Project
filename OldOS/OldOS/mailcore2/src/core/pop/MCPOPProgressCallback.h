#ifndef MAILCORE_MCPOPPROGRESSCALLBACK_H

#define MAILCORE_MCPOPPROGRESSCALLBACK_H

#ifdef __cplusplus

#include <MailCore/MCUtils.h>

namespace mailcore {
    
    class POPSession;
    
    class MAILCORE_EXPORT POPProgressCallback {
    public:
        virtual void bodyProgress(POPSession * session, unsigned int current, unsigned int maximum) {};
    };
    
}

#endif

#endif
