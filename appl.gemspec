#
#  appl.gemspec  --  Appl Gem specification
#

Gem::Specification.new do |s|
  s.name              = "appl"
  s.rubyforge_project = "NONE"
  s.version           = "1.0"
  s.summary           = "Easy option parsing"
  s.description       = <<EOT
A base class for command line applications doing options parsing
and generating exit codes.
EOT
  s.license           = "BSD"
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de"

  s.requirements      = "Just Ruby"
  s.add_dependency      "supplement", ">=1.6"

  s.extensions        = %w()
  s.files             = %w(
                          lib/appl.rb
                          lib/intar.rb
                          doc/demoappl
                        )
  s.executables       = %w(
                          intar
                        )

  s.has_rdoc          = true
end

