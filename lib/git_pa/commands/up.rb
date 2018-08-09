# frozen_string_literal: true

require_relative '../command'
require_relative '../config'
require_relative '../repo'
require_relative '../git'
require_relative '../colors'
require 'tty-progressbar'

module GitPa
  module Commands
    class Up < GitPa::Command
      def initialize(options)
        @options = options
        @config = GitPa::Config.load
        @repos = @config[:repos].map { |r| GitPa::Repo.new(@config, r) }
      end

      def execute(input: $stdin, output: $stdout)
        progress = begin_progress
        branch = ARGV[1] || 'master'

        response = []
        @repos.each do |repo|
          local_res = []
          git = Git.new(repo, branch)
          response << "Updating #{repo.name.bold} on branch #{git.branch.underline}".colorize(:blue)

          local_res << git.checkout
          local_res << git.pull
          color, local_res = Colors.paint(local_res)
          response << local_res

          break if color == :red
          progress.advance
        end

        output.puts "\n"
        output.puts response.flatten.join("\n")
      end

      private

      def begin_progress
        repo_names = @repos.map { |r| r.name.bold }.join(', ')
        puts "Updating repos: #{repo_names}".colorize(:blue)

        progress = TTY::ProgressBar.new('[:bar] :percent', total: @repos.length, width: 30)
        progress.advance(0)
        progress
      end
    end
  end
end
