import Foundation

import ArgumentParser



/* This is the completion script for xct. We call it meta because it’s able to
 * call the sub-completion scripts for sub-commands properly. */
struct GenerateMetaCompletionScript : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Generate the completion script for xct. We use another algorithm than ArgumentParser’s, but I did not find a way to override the completion script from ArgumentParser, so I created a new command."
	)
	
	enum Shell : String, CaseIterable, ExpressibleByArgument {
		
		case zsh
		case bash
		
	}
	
	@Argument
	var shellName = Shell.zsh
	
	func run() throws {
		switch shellName {
			case .zsh:  print(Self.zshCompletion)
			case .bash: print(Self.bashCompletion)
		}
	}
	
	private static let zshCompletion = """
		#compdef xct
		local context state state_descr line
		_xct_commandname=$words[1]
		typeset -A opt_args
		
		_xct() {
			integer ret=1
			local -a args
			args+=(
				'--exec-path[Set the path to the core xct programs.]:exec-path:_files -/'
				'-C[Change working directory before calling the tool.]:path:_files -/'
				':tool-name:{_custom_completion $_xct_commandname ---completion  -- toolName $words}'
				':tool-arguments:{_custom_completion $_xct_commandname ---completion  -- toolArguments $words}'
				'(-h --help)'{-h,--help}'[Print help information.]'
			)
			_arguments -w -s -S $args[@] && ret=0
			
			return ret
		}
		
		
		_custom_completion() {
			local completions=("${(@f)$($*)}")
			_describe '' completions
		}
		
		_xct
		"""
	
	private static let bashCompletion = """
		#!/bin/bash
		
		_xct() {
			cur="${COMP_WORDS[COMP_CWORD]}"
			prev="${COMP_WORDS[COMP_CWORD-1]}"
			COMPREPLY=()
			opts="--exec-path -C -h --help"
			opts="$opts $(xct ---completion  -- toolName "$COMP_WORDS")"
			opts="$opts $(xct ---completion  -- toolArguments "$COMP_WORDS")"
			if [[ $COMP_CWORD == "1" ]]; then
				COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
				return
			fi
			case $prev in
				--exec-path)
					COMPREPLY=( $(compgen -d -- "$cur") )
					return
				;;
				-C)
					COMPREPLY=( $(compgen -d -- "$cur") )
					return
				;;
			esac
			COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
		}
		
		
		complete -F _xct xct
		"""
	
}
