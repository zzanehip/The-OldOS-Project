# Files to build

set(async_imap_files
  async/imap/MCIMAPAppendMessageOperation.cpp
  async/imap/MCIMAPAsyncConnection.cpp
  async/imap/MCIMAPAsyncSession.cpp
  async/imap/MCIMAPCapabilityOperation.cpp
  async/imap/MCIMAPCheckAccountOperation.cpp
  async/imap/MCIMAPConnectOperation.cpp
  async/imap/MCIMAPCopyMessagesOperation.cpp
  async/imap/MCIMAPMoveMessagesOperation.cpp
  async/imap/MCIMAPCreateFolderOperation.cpp
  async/imap/MCIMAPDeleteFolderOperation.cpp
  async/imap/MCIMAPDisconnectOperation.cpp
  async/imap/MCIMAPExpungeOperation.cpp
  async/imap/MCIMAPFetchContentOperation.cpp
  async/imap/MCIMAPFetchContentToFileOperation.cpp
  async/imap/MCIMAPFetchParsedContentOperation.cpp
  async/imap/MCIMAPFetchFoldersOperation.cpp
  async/imap/MCIMAPFetchMessagesOperation.cpp
  async/imap/MCIMAPFetchNamespaceOperation.cpp
  async/imap/MCIMAPFolderInfo.cpp
  async/imap/MCIMAPFolderInfoOperation.cpp
  async/imap/MCIMAPFolderStatusOperation.cpp
  async/imap/MCIMAPIdentityOperation.cpp
  async/imap/MCIMAPIdleOperation.cpp
  async/imap/MCIMAPMessageRenderingOperation.cpp
  async/imap/MCIMAPMultiDisconnectOperation.cpp
  async/imap/MCIMAPOperation.cpp
  async/imap/MCIMAPQuotaOperation.cpp
  async/imap/MCIMAPRenameFolderOperation.cpp
  async/imap/MCIMAPSearchOperation.cpp
  async/imap/MCIMAPStoreFlagsOperation.cpp
  async/imap/MCIMAPStoreLabelsOperation.cpp
  async/imap/MCIMAPSubscribeFolderOperation.cpp
  async/imap/MCIMAPNoopOperation.cpp
  async/imap/MCIMAPCustomCommandOperation.cpp
)

set(async_pop_files
  async/pop/MCPOPAsyncSession.cpp
  async/pop/MCPOPCheckAccountOperation.cpp
  async/pop/MCPOPDeleteMessagesOperation.cpp
  async/pop/MCPOPFetchHeaderOperation.cpp
  async/pop/MCPOPFetchMessageOperation.cpp
  async/pop/MCPOPFetchMessagesOperation.cpp
  async/pop/MCPOPNoopOperation.cpp
  async/pop/MCPOPOperation.cpp
)

set(async_smtp_files
  async/smtp/MCSMTPAsyncSession.cpp
  async/smtp/MCSMTPCheckAccountOperation.cpp
  async/smtp/MCSMTPDisconnectOperation.cpp
  async/smtp/MCSMTPOperation.cpp
  async/smtp/MCSMTPLoginOperation.cpp
  async/smtp/MCSMTPSendWithDataOperation.cpp
  async/smtp/MCSMTPNoopOperation.cpp
)

set(async_nntp_files
  async/nntp/MCNNTPAsyncSession.cpp
  async/nntp/MCNNTPCheckAccountOperation.cpp
  async/nntp/MCNNTPDisconnectOperation.cpp
  async/nntp/MCNNTPFetchArticleOperation.cpp
  async/nntp/MCNNTPFetchAllArticlesOperation.cpp
  async/nntp/MCNNTPFetchHeaderOperation.cpp
  async/nntp/MCNNTPListNewsgroupsOperation.cpp
  async/nntp/MCNNTPFetchOverviewOperation.cpp
  async/nntp/MCNNTPFetchServerTimeOperation.cpp
  async/nntp/MCNNTPPostOperation.cpp
  async/nntp/MCNNTPOperation.cpp
)

set(async_files
  ${async_imap_files}
  ${async_pop_files}
  ${async_smtp_files}
  ${async_nntp_files}
)

# Includes for build

set(async_includes
  "${CMAKE_CURRENT_SOURCE_DIR}/async"
  "${CMAKE_CURRENT_SOURCE_DIR}/async/imap"
  "${CMAKE_CURRENT_SOURCE_DIR}/async/pop"
  "${CMAKE_CURRENT_SOURCE_DIR}/async/smtp"
  "${CMAKE_CURRENT_SOURCE_DIR}/async/nntp"
)
