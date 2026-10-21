{ inputs }: final: prev: {
  concord = inputs.concord.packages.${prev.system}.default;
  watui = inputs.watui.packages.${prev.system}.default;
}
