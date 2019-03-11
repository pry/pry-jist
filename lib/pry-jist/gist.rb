require 'gist'

module PryJist
  # @since v1.0.0
  class Gist < Pry::ClassCommand
    match 'gist'
    group 'Misc'
    description 'Upload code, docs, history to https://gist.github.com/.'

    banner <<-'BANNER'
      Usage: gist [OPTIONS] [--help]

      The gist command enables you to gist code from files and methods to github.

      gist -i 20 --lines 1..3
      gist Pry#repl --lines 1..-1
      gist Rakefile --lines 5
    BANNER

    def options(opt)
      @input_expression_ranges = []
      @output_result_ranges = []

      opt.on :l, :lines, "Restrict to a subset of lines. Takes a line number or range",
             optional_argument: true, as: Range, default: 1..-1
      opt.on :o, :out, "Select lines from Pry's output result history. Takes an index " \
                       "or range",
             optional_argument: true, as: Range, default: -5..-1 do |r|
        output_result_ranges << (r || (-5..-1))
      end
      opt.on :i, :in, "Select lines from Pry's input expression history. Takes an " \
                      "index or range",
             optional_argument: true, as: Range, default: -5..-1 do |r|
        input_expression_ranges << (r || (-5..-1))
      end
      opt.on :s, :super, "Select the 'super' method. Can be repeated to traverse " \
                         "the ancestors",
             as: :count
      opt.on :d, :doc, "Select lines from the code object's documentation"
      opt.on :login, "Authenticate the gist gem with GitHub"
      opt.on :p, :public, "Create a public gist (default: false)", default: false
      opt.on :clip, "Copy the selected content to clipboard instead, do NOT " \
                    "gist it", default: false
    end

    def process # rubocop:disable Metrics/AbcSize
      return ::Gist.login! if opts.present?(:login)

      cc = Pry::Command::CodeCollector.new(args, opts, _pry_)

      raise Pry::CommandError, "Found no code to gist." if cc.content =~ /\A\s*\z/

      if opts.present?(:clip)
        clipboard_content(cc.content)
      else
        # we're overriding the default behavior of the 'in' option (as
        # defined on CodeCollector) with our local behaviour.
        content = opts.present?(:in) ? input_content : cc.content
        gist_content content, cc.file
      end
    end

    def clipboard_content(content)
      ::Gist.copy(content)
      output.puts "Copied content to clipboard!"
    end

    def input_content # rubocop:disable Metrics/AbcSize
      content = ""
      Pry::Command::CodeCollector.input_expression_ranges.each do |range|
        input_expressions = _pry_.input_ring[range] || []
        Array(input_expressions).each_with_index do |code, index|
          corrected_index = index + range.first
          next unless code && code != ""

          content << code
          next unless code !~ /;\Z/

          content << comment_expression_result_for_gist(
            _pry_.config.gist.inspecter.call(_pry_.output_ring[corrected_index])
          ).to_s
        end
      end

      content
    end

    def comment_expression_result_for_gist(result)
      content = ""
      result.lines.each_with_index do |line, index|
        content << index == 0 ? "# => #{line}" : "#    #{line}"
      end

      content
    end

    def gist_content(content, filename)
      response = ::Gist.gist(
        content,
        filename: filename || "pry_gist.rb",
        public: !!opts[:p] # rubocop:disable Style/DoubleNegation
      )
      return unless response

      url = response['html_url']
      message = "Gist created at URL #{url}"
      begin
        ::Gist.copy(url)
        message << ", which is now in the clipboard."
      rescue ::Gist::ClipboardError # rubocop:disable Lint/HandleExceptions
      end

      output.puts message
    end
  end
end

Pry::Commands.add_command(PryJist::Gist)
Pry::Commands.alias_command 'clipit', 'gist --clip'
