(* This is free and unencumbered software released into the public domain. *)

module Topic : sig
  type t
  val create : string list -> t
  val path : t -> string list
  val message_type : t -> string
  val qos_policy : t -> int
  val to_string : t -> string
end