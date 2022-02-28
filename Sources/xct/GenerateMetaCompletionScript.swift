import Foundation

import ArgumentParser



/* This is the completion script for xct.
 * We call it meta because it’s able to call the sub-completion scripts for sub-commands properly. */
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
	
	/* Resources:
	 * - Introduction to zsh completion script: https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org
	 *     Permalink: https://github.com/zsh-users/zsh-completions/blob/6fbf5fc9a7033bc47d4c61b2d6b97fe0c74d9c45/zsh-completions-howto.org
	 * - Details about _arguments: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Utility-Functions-1
	 * - zsh-users completion style guide: https://github.com/zsh-users/zsh/blob/master/Etc/completion-style-guide
	 *     Permalink: https://github.com/zsh-users/zsh/blob/ef60187efce77c0572daf419ca5ba57a28df3cad/Etc/completion-style-guide
	 * - git’s completion: file:///usr/share/zsh/5.8/functions/_git */
	private static let zshCompletion = ##"""
		#compdef xct
		local context state state_descr line
		_xct_commandname="$words[1]"
		typeset -A opt_args
		
		_xct() {
			local curcontext=$curcontext
		
			integer ret=1
			local -a args
			args+=(
				'(-h --help)'{-h,--help}'[Print help information.]'
				'--exec-path[Set the path to the core xct programs.]: :_directories'
				'-C[Change working directory before calling the tool.]: :_directories'
				'(-): :{_custom_completion "$_xct_commandname" ---completion  -- toolName $words}'
				'(-)*:: :->sub-command'
			)
			_arguments -C -w -s -S "${args[@]}" && return
		
			case $state in
				(sub-command)
					curcontext=${curcontext%:*:*}:xct-$words[1]:
					_call_function ret _xct-$words[1]
					;;
			esac
		
			return ret
		}
		
		_custom_completion() {
			local completions=("${(@f)$($*)}")
			_describe '' completions
		}
		
		_xct
		
		# Below is git’s completion script (w/ git renamed to xct).
		# Used as an inspiration.
		# Can be used again if we want to implement aliases someday for instance.
		
		#_xct() {
		#	if (( CURRENT > 2 )); then
		#		local -a aliases
		#		local -A xct_aliases
		#		local a k v
		#		local endopt='!(-)--end-of-options'
		#		aliases=(${(0)"$(_call_program aliases xct config -z --get-regexp '\^alias\.')"})
		#		for a in ${aliases}; do
		#				k="${${a/$'\n'*}/alias.}"
		#				v="${a#*$'\n'}"
		#				xct_aliases[$k]="$v"
		#		done
		#
		#		if (( $+xct_aliases[$words[2]] && !$+commands[xct-$words[2]] && !$+functions[_xct-$words[2]] )); then
		#			local -a tmpwords expalias
		#			expalias=(${(z)xct_aliases[$words[2]]})
		#			tmpwords=(${words[1]} ${expalias})
		#			if [[ -n "${words[3,-1]}" ]] ; then
		#				tmpwords+=(${words[3,-1]})
		#			fi
		#			[[ -n ${words[$CURRENT]} ]] || tmpwords+=('')
		#			(( CURRENT += ${#expalias} - 1 ))
		#			words=("${tmpwords[@]}")
		#			unset tmpwords expalias
		#		fi
		#
		#		unset xct_aliases aliases
		#	fi
		#
		#	integer ret=1
		#
		#	if [[ $service == xct ]]; then
		#		local curcontext=$curcontext state line
		#		declare -A opt_args
		#
		#		_arguments -C -w -s -S \
		#			'(-h --help)'{-h,--help}'[Print help information.]' \
		#			'--exec-path[Set the path to the core xct programs.]: :_directories' \
		#			'-C[Change working directory before calling the tool.]: :_directories' \
		#			'(-): :{_custom_completion "$_xct_commandname" ---completion  -- toolName $words}' \
		#			'(-)*:: :->sub-command' && return
		#
		#		case $state in
		#			(command)
		#				_xct_commands && ret=0
		#				;;
		#			(sub-command)
		#				curcontext=${curcontext%:*:*}:xct-$words[1]:
		#				(( $+opt_args[--xct-dir] )) && local -x xct_DIR=$opt_args[--xct-dir]
		#				if ! _call_function ret _xct-$words[1]; then
		#					if [[ $words[1] = \!* ]]; then
		#						words[1]=${words[1]##\!}
		#						_normal && ret=0
		#					elif zstyle -T :completion:$curcontext: use-fallback; then
		#						_default && ret=0
		#					else
		#						_message "unknown sub-command: $words[1]"
		#					fi
		#				fi
		#				;;
		#			(configuration)
		#				if compset -P 1 '*='; then
		#					__xct_config_value && ret=0
		#				else
		#					if compset -S '=*'; then
		#						__xct_config_option && ret=0 # don't move cursor if we completed just the "foo." in "foo.bar.baz=value"
		#						compstate[to_end]=''
		#					else
		#						__xct_config_option -S '=' && ret=0
		#					fi
		#				fi
		#				;;
		#		esac
		#	else
		#		_call_function ret _$service
		#	fi
		#
		#	return ret
		#}
		#
		# Load any _xct-* definitions so that they may be completed as commands.
		#declare -gUa _xct_external_commands
		#_xct_external_commands=()
		#
		#local file input
		#for file in ${^fpath}/_xct-*~(*~|*.zwc)(-.N); do
		#	local name=${${file:t}#_xct-}
		#	if (( $+_xct_external_commands[$name] )); then
		#		continue
		#	fi
		#
		#	local desc=
		#	integer i=1
		#	while read input; do
		#		if (( i == 2 )); then
		#			if [[ $input == '#description '* ]]; then
		#				desc=:${input#\#description }
		#			fi
		#			break
		#		fi
		#		(( i++ ))
		#	done < $file
		#
		#	_xct_external_commands+=$name$desc
		#done
		"""##
	
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
