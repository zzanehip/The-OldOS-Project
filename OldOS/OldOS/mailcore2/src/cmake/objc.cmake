# Files to build

set(objc_abstract_files
  objc/abstract/MCOAbstractMessage.mm
  objc/abstract/MCOAbstractMessagePart.mm
  objc/abstract/MCOAbstractMessageRendererCallback.mm
  objc/abstract/MCOAbstractMultipart.mm
  objc/abstract/MCOAbstractPart.mm
  objc/abstract/MCOAddress.mm
  objc/abstract/MCOMessageHeader.mm
)

set(objc_imap_files
  objc/imap/MCOIMAPAppendMessageOperation.mm
  objc/imap/MCOIMAPBaseOperation.mm
  objc/imap/MCOIMAPCapabilityOperation.mm
  objc/imap/MCOIMAPCopyMessagesOperation.mm
  objc/imap/MCOIMAPMoveMessagesOperation.mm
  objc/imap/MCOIMAPFetchContentOperation.mm
  objc/imap/MCOIMAPFetchContentToFileOperation.mm
  objc/imap/MCOIMAPFetchParsedContentOperation.mm
  objc/imap/MCOIMAPFetchFoldersOperation.mm
  objc/imap/MCOIMAPFetchMessagesOperation.mm
  objc/imap/MCOIMAPFetchNamespaceOperation.mm
  objc/imap/MCOIMAPFolder.mm
  objc/imap/MCOIMAPFolderInfo.mm
  objc/imap/MCOIMAPFolderInfoOperation.mm
  objc/imap/MCOIMAPFolderStatus.mm
  objc/imap/MCOIMAPFolderStatusOperation.mm
  objc/imap/MCOIMAPIdentity.mm
  objc/imap/MCOIMAPIdentityOperation.mm
  objc/imap/MCOIMAPIdleOperation.mm
  objc/imap/MCOIMAPMessage.mm
  objc/imap/MCOIMAPMessagePart.mm
  objc/imap/MCOIMAPMessageRenderingOperation.mm
  objc/imap/MCOIMAPMultiDisconnectOperation.mm
  objc/imap/MCOIMAPMultipart.mm
  objc/imap/MCOIMAPNamespace.mm
  objc/imap/MCOIMAPNamespaceItem.mm
  objc/imap/MCOIMAPOperation.mm
  objc/imap/MCOIMAPPart.mm
  objc/imap/MCOIMAPQuotaOperation.mm
  objc/imap/MCOIMAPSearchExpression.mm
  objc/imap/MCOIMAPSearchOperation.mm
  objc/imap/MCOIMAPNoopOperation.mm
  objc/imap/MCOIMAPCustomCommandOperation.mm
  objc/imap/MCOIMAPCheckAccountOperation.mm
  objc/imap/MCOIMAPSession.mm
)

set(objc_pop_files
  objc/pop/MCOPOPFetchHeaderOperation.mm
  objc/pop/MCOPOPFetchMessageOperation.mm
  objc/pop/MCOPOPFetchMessagesOperation.mm
  objc/pop/MCOPOPNoopOperation.mm
  objc/pop/MCOPOPMessageInfo.mm
  objc/pop/MCOPOPOperation.mm
  objc/pop/MCOPOPSession.mm
)

set(objc_provider_files
  objc/provider/MCOMailProvider.mm
  objc/provider/MCOMailProvidersManager.mm
  objc/provider/MCONetService.mm
  objc/provider/MCOAccountValidator.mm
)

set(objc_rfc822_files
  objc/rfc822/MCOAttachment.mm
  objc/rfc822/MCOMessageBuilder.mm
  objc/rfc822/MCOMessageParser.mm
  objc/rfc822/MCOMessagePart.mm
  objc/rfc822/MCOMultipart.mm
)

set(objc_smtp_files
  objc/smtp/MCOSMTPOperation.mm
  objc/smtp/MCOSMTPLoginOperation.mm
  objc/smtp/MCOSMTPSendOperation.mm
  objc/smtp/MCOSMTPNoopOperation.mm
  objc/smtp/MCOSMTPSession.mm
)

set(objc_nntp_files
  objc/nntp/MCONNTPDisconnectOperation.mm
  objc/nntp/MCONNTPFetchArticleOperation.mm
  objc/nntp/MCONNTPFetchAllArticlesOperation.mm
  objc/nntp/MCONNTPFetchHeaderOperation.mm
  objc/nntp/MCONNTPGroupInfo.mm
  objc/nntp/MCONNTPListNewsgroupsOperation.mm
  objc/nntp/MCONNTPFetchOverviewOperation.mm
  objc/nntp/MCONNTPFetchServerTimeOperation.mm
  objc/nntp/MCONNTPPostOperation.mm
  objc/nntp/MCONNTPOperation.mm
  objc/nntp/MCONNTPSession.mm
)

set(objc_utils_files
  objc/utils/MCOIndexSet.mm
  objc/utils/MCOObjectWrapper.mm
  objc/utils/MCOOperation.mm
  objc/utils/MCORange.mm
  objc/utils/NSArray+MCO.mm
  objc/utils/NSData+MCO.mm
  objc/utils/NSDictionary+MCO.mm
  objc/utils/NSError+MCO.mm
  objc/utils/NSObject+MCO.mm
  objc/utils/NSString+MCO.mm
  objc/utils/NSValue+MCO.mm
  objc/utils/NSIndexSet+MCO.m
)

IF(APPLE)
set(objc_files
  ${objc_abstract_files}
  ${objc_imap_files}
  ${objc_pop_files}
  ${objc_provider_files}
  ${objc_nntp_files}
  ${objc_rfc822_files}
  ${objc_smtp_files}
  ${objc_utils_files}
)
ENDIF()

# Includes for build

set(objc_includes
  "${CMAKE_CURRENT_SOURCE_DIR}/objc"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/abstract"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/imap"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/pop"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/provider"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/nntp"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/rfc822"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/smtp"
  "${CMAKE_CURRENT_SOURCE_DIR}/objc/utils"
)
