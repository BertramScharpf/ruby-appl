#
#  appl.gemspec  --  Appl Gem specification
#

Gem::Specification.new do |s|
  s.name              = "appl"
  s.rubyforge_project = "appl"
  s.version           = "1.0"
  s.summary           = "Easy option parsing"
  s.description       = <<EOT
A base class for command line applications doing options parsing
and generating exit codes.
EOT
  s.authors           = [ "Bertram Scharpf"]
  s.email             = "<software@bertram-scharpf.de>"
  s.homepage          = "http://www.bertram-scharpf.de"

  s.requirements      = "Just Ruby"
# s.add_dependency      "somegem", ">=0.1"

  s.extensions        = nil
  s.files             = %w(
                          lib/appl.rb
                          doc/demoappl
                        )
  s.executables       = %w(
                        )

  s.has_rdoc          = true
end

