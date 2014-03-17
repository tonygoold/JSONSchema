Pod::Spec.new do |s|

  s.name         = "JSONSchema"
  s.version      = "0.0.1"
  s.summary      = "Library for defining JSON schemas and validating data against them."

  s.description  = <<-DESC
                   This is a library to simplify the process of checking JSON data against
                   a schema. JSON schemas can be generated automatically from prototype
                   plist objects. Unlike RestKit, JSONSchema is not an ORM library, it is
                   intended specifically for catching and filtering bad data.

                   * Define a schema by providing an example of the data it should accept
                   * Support for optional fields
                   * Support for recursive structures
                   * Convert invalid data to valid data by providing default values
                   DESC

  s.homepage     = "https://github.com/tonygoold/JSONSchema"

  s.license      = 'Apache License, Version 2.0'

  s.author             = { "R. Tony Goold" => "tony@goold.net" }
  s.social_media_url = "https://twitter.com/tonygoold"

  s.source       = { :git => "https://github.com/tonygoold/JSONSchema.git", :tag => "0.0.1" }

  s.source_files  = 'JSONSchema'

  s.requires_arc = true

end
