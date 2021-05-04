require "faker"

module Pg::Anon
  VERSION = "0.1.0"

  class Anonymizer
    @type : String

    def initialize(type)
      @type = type
    end

    def fake(value)
      case @type
      when "email"
        Faker::Internet.email
      when "name"
        Faker::Name.name
      when "encrypted"
        Faker::Lorem.characters(20)
      when "first_name"
        Faker::Name.first_name
      when "last_name"
        Faker::Name.last_name
      when "phone"
        Faker::PhoneNumber.phone_number
      when "empty"
        ""
      else
        value
      end
    end
  end

  class Iterator
    @mappings : Array({col: String, faker: String})
    @table : String?

    def initialize(mappings)
      @mappings = mappings
      @table = nil
      @columns = [] of String
      @indices = [] of Int32
      @transformers = [] of Anonymizer
    end

    def process_line(line)
      if line.starts_with?("COPY")
        process_table(line)
        line
      elsif @table && line.strip != ""
        process_row(line)
      else
        @table = nil
        line
      end
    end

    private def process_table(line)
      @table = line.gsub(/^COPY (.*?) .*$/, "\\1")
      @columns = line.gsub(/^COPY (?:.*?) \((.*)\).*$/, "\\1")
        .split(",")
        .map { |s| s.strip.gsub(/"/, "").downcase }
      @transformers = @columns.map do |column|
        faker = (@mappings.find { |m| m[:col] == column } || {faker: ""})[:faker]
        Anonymizer.new(faker)
      end
    end

    private def process_row(line)
      line.split("\t")
        .map_with_index { |val, idx|
          @transformers[idx].fake(val)
        }
        .join("\t")
    end
  end

  class Processor
    property file : String
    property output : String
    property tables : String
    property fields : String

    def initialize
      @file = "./in.sql"
      @output = "./out.sql"
      @tables = ""
      @fields = ""
    end

    def run
      mappings = fields.split(",").map do |l|
        {
          col:   l.gsub(/:(?:.*)$/, "").downcase,
          faker: l.includes?(":") ? l.gsub(/^(?:.*):/, "") : "",
        }
      end

      iterator = Iterator.new(mappings)
      File.open(@output, "w") do |writer|
        File.each_line(@file) do |line|
          writer.puts iterator.process_line(line)
        end
      end
    end
  end
end
