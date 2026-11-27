{ config, ... }: {
  sops.secrets."ntfy-client-env" = {
    owner = config.users.users.nic.name;
    mode = "0400";
  };
}
