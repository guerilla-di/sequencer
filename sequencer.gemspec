Gem::Specification.new do |s|
  s.name = "sequencer"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Julik Tarkhanov"]
  s.date = "2014-02-18"
  s.email = "me@julik.nl"
  s.executables = ["rseqls", "rseqpad", "rseqrename"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = `git ls-files -z`.split("\x0")
  s.homepage = "http://guerilla-di.org/sequencer"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Image sequence sorting, scanning and manipulation"
  s.specification_version = 4
  s.add_development_dependency("rake", [">= 0"])
  s.add_development_dependency("minitest", [">= 0"])
end
