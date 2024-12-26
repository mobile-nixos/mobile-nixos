#!/usr/bin/env nix-shell
#!nix-shell -p 'ruby.withPackages (r: [ r.parallel r.ruby-progressbar ])' nix -i ruby

require "json"
require "open3"
require "shellwords"
require "parallel"
require "ruby-progressbar"

DO_EVAL = !ARGV.include?("--skip-eval")
VERBOSE = ARGV.include?("--verbose")
SOURCE_EXPRESSION = [
  (ARGV.find{_1.match(/^--source=/)}&.split("=",2)&.last),
  File.join(__dir__(), "default.nix"),
].compact.first

$stderr.puts "Checking for no-ops as configured in #{SOURCE_EXPRESSION.inspect()}"

def verbose_cmd(*cmd)
  $stderr.puts " $ #{cmd.shelljoin}" if VERBOSE
end

class String
  def to_nix()
    self.to_json()
  end
end

class Array
  def to_nix()
    [
      "[",
      self.map do |el|
        [
          "(",
          el.to_nix(),
          ")",
        ].join("")
      end.join(" "),
      "]",
    ].join(" ")
  end
end

module Nix
  extend self

  def instantiate(*cmd_args, expr: nil, args: {}, fail: true)
    if VERBOSE
      $stderr.puts "Expression:"
      $stderr.puts expr.inspect
    end
    cmd = ["nix-instantiate", "--json", "--strict", "--eval" ]
    cmd << "-" if expr
    args.each do |name, value|
      cmd << "--arg"
      cmd << name.to_s()
      cmd << value.to_nix()
    end
    cmd.concat(*cmd_args)
    verbose_cmd(*cmd)
    result, stderr, status = Open3.capture3(*cmd, stdin_data: expr)

    if status.success?
      return JSON.parse(result), stderr, status
    else
      if fail
        $stderr.puts ""
        $stderr.puts "Nix evaluation unexpectedly failed."
        $stderr.puts ""
        $stderr.puts stderr
        $stderr.puts ""
        raise "Command unexpectedly failed."
      else
        return nil, stderr, status
      end
    end
  end
end

# Things to do with a NixOS evaluation
class NixOS
  attr_reader :expr

  # expr should evaluate to a NixOS-like system.
  def initialize(expr)
    @expr = expr
  end

  # returns a list of option paths for the current expression.
  def options_list()
    @options ||=
      begin
        expression = %Q{
          let
            dumpOptionsDefs =
              { path ? [], options }:

              builtins.concatLists (
                builtins.map
                (name:
                let
                  current = path ++ [ name ];
                  value = options.${name};
                in
                if value ? _type && value._type == "option"
                then [ current ]
                else (dumpOptionsDefs { path = current; options = value; })
                )
                (builtins.attrNames options)
              )
            ;
          in
          dumpOptionsDefs { inherit (#{@expr}) options; }
        }
        result, _, _ = Nix.instantiate(expr: expression)
        result
      end
  end

  def get_option(path)
    path = path.split(".") unless path.is_a? Enumerable
      begin
        expression = %Q{
          { path }:
          let
            eval = (#{@expr});
            inherit (eval.pkgs.lib)
              getAttrFromPath
            ;
            option = getAttrFromPath path eval.options;
          in
          if path == [ "lib" ]
          then {
            value = builtins.attrNames option.value;
            inherit (option) files;
          }
          else
            {
              inherit ({ defaultText = null; } // option)
                declarationPositions
                files
                defaultText
                description
              ;
            }
        }
        result, stderr, status = Nix.instantiate(expr: expression, args: {
          path: path,
        }, fail: false)
        if status.success?
          result
        else
          {
            "error" => {
              "exit" => status.exitstatus,
              "message" => "Command unexpectedly failed (#{status.exitstatus.inspect})",
              "stdout" => result,
              "stderr" => stderr,
            }
          }
        end
      end
  end
end

$stderr.puts ""
$stderr.puts "Checking source expression: #{SOURCE_EXPRESSION.inspect}"

# Pick the evals from the expression.
eval_attributes, _, _ = Nix.instantiate(expr: %Q{(import #{SOURCE_EXPRESSION} {}).no-op-checks.evals})
evals = eval_attributes.map do |name|
  [
    name,
    NixOS.new(
      %Q{ (import #{SOURCE_EXPRESSION} {}).#{name} },
    )
  ]
end
.to_h

$stderr.puts ""
$stderr.puts "Checking these attributes:"
$stderr.puts ""
evals.each do |name, _|
  $stderr.puts " - #{name}"
end

$ignored_options, _, _ = Nix.instantiate(expr: %Q{(import #{SOURCE_EXPRESSION} {}).no-op-checks.ignoredOptions})

$stderr.puts ""
$stderr.puts "Ignoring these options:"
$stderr.puts ""
$ignored_options.each do |path|
  $stderr.puts " - #{path.to_json()}"
end
$stderr.puts ""

# Evaluate all options, this takes a while.
all_options = evals.map do |name, evl|
  filename = "options-eval__#{name}.eval.json"

  if DO_EVAL || !File.exist?(filename)
    result = (Parallel.map(evl.options_list(), progress: "Evaluating options for: #{name}") do |path|
      [path, evl.get_option(path)]
    end).to_h
    File.write(filename, JSON.pretty_generate(result))
  else
    $stderr.puts "NOTE: skipping evaluation for #{name}, using possibly stale results."
  end

  # Round-trip the JSON so we can use saved evals and get the same exact result
  [name, JSON.parse(File.read(filename))]
end.to_h()

# Find new top-level option sets.
new_toplevel = all_options.map do |name, list|
  list.keys.map do |key|
    JSON.parse(key).first
  end
  .uniq
end
common_toplevel = new_toplevel.reduce(&:intersection)
all_toplevel = new_toplevel.reduce(&:concat).uniq
new_toplevel = all_toplevel - common_toplevel
$stderr.puts ""
$stderr.puts "New option sets at toplevel skipped from diff:"
new_toplevel.each do |name|
  $stderr.puts " - #{name}"
end

# Drop any new top-level option set from the diff, it will obviously be newly defined here.
all_options.transform_values! do |list|
  list.select do |k, v|
    !new_toplevel.include?((JSON.parse(k)).first)
  end
end

# Keep all options that did not change.
common = all_options.values.map(&:to_a).reduce(&:intersection)

# Keep content from the last attribute
diff = (all_options[eval_attributes.last].to_a() - common).to_h

# Ignore some "safe" changes
diff.select! do |key, _|
  !$ignored_options.include?(JSON.parse(key))
end

$stderr.puts ""
$stderr.puts "There are #{diff.keys.length} options that differ."
diff.each do |name, value|
  $stderr.puts " - #{JSON.parse(name).join(".")}"
end

File.write("options-eval-diff.eval.json", JSON.pretty_generate(diff))

unless diff.keys.length == 0
  exit 1
end

exit 0
