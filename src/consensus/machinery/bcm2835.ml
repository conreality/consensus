(* This is free and unencumbered software released into the public domain. *)

open Prelude

class implementation = object (self)
  inherit Device.interface as super

  method is_privileged = true

  method driver_name = "bcm2835"

  method device_name = "bcm2835"
end

type t = implementation
