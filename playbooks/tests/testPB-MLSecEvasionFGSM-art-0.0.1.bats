@test "bes run -P MLSecEvasionFGSM-art -V 0.0.1 runs playbook and expects to generate an OSAR" {
  run bash -c 'source $HOME/.besman/bin/besman-init.sh && bes run -P MLSecEvasionFGSM-art -V 0.0.1'
  echo "$output"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Playbook"* ]]
  [[ "$output" == *"OSAR"* ]]

}
