{
  outputs = { self, nixpkgs }: {
    devShell.x86_64-linux = with import nixpkgs { system = "x86_64-linux"; };
      mkShell {
        buildInputs = [ swiProlog scryer-prolog ];
      };
  };
}
