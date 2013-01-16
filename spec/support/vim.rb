module Support
  module Vim
    FILENAME = 'text.txt'

    def set_file_contents(string)
      string = normalize_string(string)
      File.open(FILENAME, 'w') { |f| f.write(string) }
      VIM.instance.edit FILENAME
    end

    def assert_file_contents(string)
      string = normalize_string(string)
      IO.read(FILENAME).strip.should eq string
    end

    def smartpairs(type, mod)
      cmd = "SmartPairs#{mod.upcase} #{type}"
      VIM.instance.command cmd
    end

    def nextpairs
      cmd = "NextPairs"
      VIM.instance.command cmd
    end

    def toggle_uber_mode
      cmd = "NextPairsToggleUberMode"
      VIM.instance.command cmd
    end

    def apply_commands(commands)
      commands.split("\n").each do |command|
        if /SmartPairs(I|A)\s(v|c|d|y)/ =~ command
          smartpairs $2, $1
        elsif /NextPairsToggleUberMode/ =~ command
          toggle_uber_mode
        elsif /NextPairsA?/ =~ command
          nextpairs
        elsif /sleep/ =~ command
          sleep 20
        elsif /^#/ =~ command
          #skip comments
        else
          VIM.instance.type command
        end
      end
      VIM.instance.write
    end

    private

    def normalize_string(string)
      whitespace = string.scan(/^\s*/).first
      string.split("\n").map { |line| line.gsub /^#{whitespace}/, '' }.join("\n").strip
    end
  end
end
