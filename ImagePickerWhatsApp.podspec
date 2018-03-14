
Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "ImagePickerWhatsApp"
  s.version      = "0.0.1"
  s.summary      = "Capture Image, Capture Video, Select Image from Library, Select Video from Library."

  s.description  = <<-DESC
i was searching for a pod that will allow me to select media files like whatsapp does, but i wasn't able to find one so i created my own.
                   DESC

  s.homepage     = "http://EXAMPLE/ImagePickerWhatsApp"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "ion utale" => "ion.utale@icloud.com" }
  s.platform     = :ios, "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/jhonyourangel/ImagePickerWhatsApp.git", :tag => "#{s.version}" }

  s.source_files = "ImagePickerWhatsApp/*"
  s.resource  = "ImagePickerWhatsApp/*"
s.framework = "UIKit"
s.framework = "Foundation"
s.framework = "Photos"
s.framework = "AVFoundation"


end
