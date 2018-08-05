# frozen_string_literal: true

require_relative '../command'
require_relative '../config'
require 'yaml'
require 'colorize'
require 'pry'

module GitPa
  module Commands
    class Config < GitPa::Command

      def initialize(options)
        @options = options
        @config = GitPa::Config.load
        @defaults = GitPa::Config.defaults
      end

      def execute(input: $stdin, output: $stdout)
        body = @defaults
        body.merge!(@config) unless @config.nil?

        output.puts "============= \n\n\n"
        prompt_repos(body)
        prompt_branch_aliases(body, output)
        prompt_pull_strategy(body)

        save_config(body)
        output.puts 'Config saved in ~/.git_parc'.colorize(:green)
      end

      private

      def prompt_repos(body)
        result = prompt.ask('Git repo directories (separated by spaces):', required: true)
        body[:repos] = result.split(/ \s*/)
      end

      def prompt_branch_aliases(body, output)
        output.puts(%{
Git branch aliases
2 of your repos may use 'master', while the 3rd uses 'master_v2'.
Use an alias to keep all 3 in sync.
        })
        output.puts 'Input format: `branch_name:branch_name_alias`'.colorize(:yellow)

        result = prompt.yes?('Would you like to configure aliases?')
        return unless result

        body[:repos].each do |repo|
          repo_name = repo.split('/').last
          result = prompt.ask("Alias for `#{repo_name}`:")
          next unless result && !result.strip.empty?

          branch_pairs = result.split(/ \s*/)
          body[:branch_aliases] << { name: repo_name }.tap do |obj|
            branch_pairs.each do |pair|
              branches = pair.split(':')
              obj[branches[0]] = branches[1]
            end
          end
        end
      end

      def prompt_pull_strategy(body)
        result = prompt.ask(
          "Pull strategy (leave empty for default: `#{@defaults[:pull_strategy]}`):"
        )
        if result && !result.strip.empty?
          body[:pull_strategy] = pull_strategy
        end
      end

      def save_config(body)
        file = File.new(GitPa::Config::CONFIG_FILE, 'w')
        file.puts(body.to_yaml)
        file.close
      end
    end
  end
end
