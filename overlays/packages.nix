{ inputs }: final: prev: {
  watui = inputs.watui.packages.${prev.system}.default;
}
