export def defined_external [command: string]: nothing -> bool {
  which $"^($command)" | is-not-empty
}

export def pick_external [
  ...commands: string
  ]: nothing -> string {
  $commands | each {|e| $"^($e)"} | which ...$in | get path | first
}
