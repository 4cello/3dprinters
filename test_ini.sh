#! /usr/bin/env sh

nix eval --raw --impure --expr '
with import <nixpkgs> {};
let
foo = import ./configs/common.nix { lib = lib; };
in
lib.generators.toINI {} (foo.services.moonraker.settings)
' > output.ini

python3 << EOF
import configparser
import json

parser = configparser.ConfigParser()
parser.read("output.ini")
print(json.dumps(parser.sections()))
EOF
