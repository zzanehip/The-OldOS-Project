//
//  MCDataDecoderUtils.h
//  mailcore2
//
//  Copyright © 2016 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCDATADECODERUTILS_H

#define MAILCORE_MCDATADECODERUTILS_H

#include <MailCore/MCData.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {

    Data * MCDecodeData(Data * encodedData, Encoding encoding, bool partialContent, Data ** pRemainingData);

}

#endif

#endif
