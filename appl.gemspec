#
#  appl.gemspec  --  Appl Gem specification
#

require "./lib/appl"

Gem::Specification.new do |s|
  s.name              = "appl"
  s.version           = Application::APPL_VERSION
  s.summary           = "Easy option parsing"
  s.description       = <<~EOT
    A base class for command line applications doing options parsing
    and generating exit codes.
  EOT
  s.license           = "BSD-2-Clause"
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de/software/appl"

  s.requirements      = "Just Ruby"

  s.extensions        = %w()
  s.files             = %w(
                          lib/appl.rb
                          lib/applfan.rb
                          doc/demoappl
                          doc/demofan
                        )
  s.executables       = %w(
                        )
end

