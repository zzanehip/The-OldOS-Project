Pod::Spec.new do |spec|
  spec.name         = "mailcore2-osx"
  spec.version      = "0.6.4"
  spec.summary      = "Mailcore 2 for OS X"
  spec.description  = "MailCore 2 provide a simple and asynchronous API to work with e-mail protocols IMAP, POP and SMTP. The API has been redesigned from ground up."
  spec.homepage     = "https://github.com/MailCore/mailcore2"
  spec.license      = { :type => "BSD", :file => "LICENSE" }
  spec.author       = "MailCore Authors"
  spec.platform     = :osx, "10.8"
  spec.source       = { :http => "https://d.etpan.org/mailcore2-deps/mailcore2-osx/mailcore2-osx-12.zip", :flatten => true }
  spec.header_dir   = "MailCore"
  spec.requires_arc = false
  spec.source_files = "include/MailCore/*.h"
  spec.public_header_files = "include/MailCore/*.h"
  spec.preserve_paths = "include/MailCore/*.h"
  spec.vendored_libraries = "lib/libMailCore.a"
  spec.libraries = ["sasl2", "tidy", "xml2", "iconv", "z", "c++", "resolv"]
  spec.prepare_command = "curl -O https://github.com/MailCore/mailcore2/raw/master/LICENSE"
end
