require "option_parser"

require "./pg-anon"

processor = Pg::Anon::Processor.new

OptionParser.parse do |parser|
  parser.banner = "Usage: pg-anon [arguments]"
  parser.on("-v", "--version", "Returns the current version") do
    puts "#{Pg::Anon::VERSION}"
    exit
  end
  parser.on("-d FILE", "--dump FILE", "File path") { |file| processor.file = file }
  parser.on("-o OUPUT", "--output OUTPUT", "") { |output| processor.output = output || "./out.sql" }
  parser.on("-f FIELDS", "--fields FIELDS", "") { |fields| processor.fields = fields || "" }
  parser.invalid_option { }
end

begin
  processor.run
rescue ex : RuntimeError
  # ignore jq errors as it writes directly to error output.
  exit 1
rescue ex
  abort "oq error: #{ex.message}"
end
