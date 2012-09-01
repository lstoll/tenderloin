module Tenderloin
  class VMXFile

    def self.load(filename)
      data = {}
      File.open(filename).each do |line|
        parts = line.split('=')
        data[parts[0].strip] = parts[1].strip.gsub!(/^"(.*?)"$/,'\1')
      end
      data
    end

    def self.write(filename, data)
      File.open(filename, 'w') do |f|
        data.each do |k,v|
          f.puts "#{k} = \"#{v}\""
        end
      end
    end

    def self.with_vmx_data(filename, &block)
      data = load(filename)
      block.call(data)
      write(filename, data)
    end

  end
end
