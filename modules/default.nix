let
  core = import ./core;
  media = import ./media;
  infra = import ./infra;
  ai = import ./ai;
  custom = import ./custom;
in
  core ++ media ++ infra ++ ai ++ custom
