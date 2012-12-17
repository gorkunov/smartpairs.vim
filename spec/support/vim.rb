module Support
  module Vim
    FILENAME = 'text.txt'
    
    def set_file_contents(string)
      string = normalize_string(string)
      File.open(FILENAME, 'w') { |f| f.write(string) }
      VIM.edit FILENAME
    end

    def assert_file_contents(string)
      string = normalize_string(string)
      IO.read(FILENAME).strip.should eq string
    end

    def smartpairs(type, mod)
      cmd = "SmartPairs#{mod.upcase} #{type}"
      VIM.command cmd
    end

    def nextpairs
      cmd = "NextPairs"
      VIM.command cmd
    end

    def apply_commands(commands)
      commands.split("\n").each do |command|
        if /SmartPairs(I|A)\s(v|c|d|y)/ =~ command
          smartpairs $2, $1
        elsif /NextPairsA?/ =~ command
          nextpairs
        elsif /sleep/ =~ command
          sleep 20
        elsif /^#/ =~ command
          #skip comments
        else
          VIM.type command
        end
      end
      VIM.write
    end

    private

    def normalize_string(string)
      whitespace = string.scan(/^\s*/).first
      string.split("\n").map { |line| line.gsub /^#{whitespace}/, '' }.join("\n").strip
    end
  end
end
