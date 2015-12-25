(* This is free and unencumbered software released into the public domain. *)

(** The `conreald` server daemon. *)

open Cmdliner
open Consensus
open Consensus.Prelude
open Consensus.Messaging
open Consensus.Networking
open Lwt.Infix
open Lwt_unix

(* Configuration *)

let version = "0.0.0"

let man_sections = [
  `S "DESCRIPTION";
  `P "Runs the Conreality daemon.";
  `S "BUGS";
  `P "Check open bug reports at <http://bugs.conreality.org>.";
  `S "SEE ALSO";
  `P "$(b,concfg)(8), $(b,conctl)(8)";
]

let udp_interface = "127.0.0.1"
let udp_port = CCCP.Protocol.port

let broker_name = "localhost"
let broker_port = 61613 (* Apache ActiveMQ Apollo *)

(* Option types *)

type verbosity = Normal | Quiet | Verbose

type common_options = { debug: bool; verbosity: verbosity }

let str = Printf.sprintf

let verbosity_str = function
  | Normal -> "normal" | Quiet -> "quiet" | Verbose -> "verbose"

(* Command implementations *)

module Experiments = struct
  let connect addr port =
    let sockfd = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    Lwt_unix.connect sockfd sockaddr
    >>= fun () -> Lwt.return (sockfd)

  let send sockfd message =
    let channel = Lwt_io.of_fd sockfd ~mode:Lwt_io.output in
    Lwt_io.write channel message
    >>= fun () -> Lwt_io.flush channel

  let recv_line sockfd =
    let channel = Lwt_io.of_fd sockfd ~mode:Lwt_io.input in
    Lwt_io.read_line channel

  let hello sockfd =
    let frame = STOMP.Protocol.make_connect_frame "localhost" "admin" "password" in
    send sockfd (STOMP.Frame.to_string frame)
    >>= fun () -> recv_line sockfd
    >>= fun (line) -> Printf.printf "%s\n" line; Lwt.return ()
    >>= fun () -> Lwt.return ()

(*
  let run server =
    ...
    Lwt_unix.gethostbyname broker_name
    >>= fun host -> begin
      Lwt_log.ign_notice_f "Connecting to message broker at %s:%d..." host.h_name broker_port;
      connect (Array.get host.h_addr_list 0) broker_port
    end
    >>= fun (sockfd) -> hello sockfd
    >>= fun () -> loop ()
*)
end

module Client = struct
  type t = Lwt_unix.sockaddr

  let compare (a : t) (b : t) =
    Pervasives.compare a b

  let to_string = function
    | ADDR_INET (addr, port) ->
      Printf.sprintf "%s:%d" (Unix.string_of_inet_addr addr) port
    | ADDR_UNIX _ -> assert false
end

module Client_set = Set.Make(Client)

module Server = struct
  type t = {
    context: Scripting.Context.t;
    mutable config: Config.t;
    mutable clients: Client_set.t;
    mutable client: Client.t
  }

  module Protocol = struct
    open Scripting

    let hello server client =
      Lwt_log.ign_notice_f "Received a hello from %s." (Client.to_string client);
      (server.clients <- Client_set.add client server.clients) |> ignore

    let bye server client =
      Lwt_log.ign_notice_f "Received a goodbye from %s." (Client.to_string client);
      (server.clients <- Client_set.remove client server.clients) |> ignore

    let enable server client = () (* TODO *)

    let disable server client = () (* TODO *)

    let toggle server client = () (* TODO *)

    let hold server client = () (* TODO *)

    let pan server client = () (* TODO *)

    let tilt server client = () (* TODO *)

    let track server client = () (* TODO *)

    let join server client = () (* TODO *)

    let leave server client = () (* TODO *)
  end

  let define server name callback =
    Scripting.Context.define server.context name
      (fun _ -> callback server server.client |> ignore; 0)

  let load_protocol server =
    define server "hello" Protocol.hello;
    define server "bye" Protocol.bye
    (* TODO *)

  let create config_path =
    let server = {
      context = Scripting.Context.create ();
      config  = Config.load_file config_path;
      clients = Client_set.empty;
      client  = Unix.(ADDR_INET (Unix.inet_addr_any, 0))
    } in
    load_protocol server;
    server

  let evaluate server client script =
    try
      server.client <- client; (* needed in Server.define callbacks *)
      Scripting.Context.eval_code server.context script
    with
    | Out_of_memory ->
      Lwt_log.ign_error "Failed to evaluate command due to memory exhaustion"
    | Scripting.Parse_error _ ->
      Lwt_log.ign_error "Failed to evaluate command due to a parse error"
    | Scripting.Runtime_error message ->
      Lwt_log.ign_error_f "Failed to evaluate command due to a runtime error: %s" message

  let recv_command socket callback =
    let buffer = (UDP.Packet.make_buffer ()) in
    let rec loop () =
      UDP.Socket.recvfrom socket buffer >>= fun (length, client) ->
      let command = String.sub (Lwt_bytes.to_string buffer) 0 length in
      Lwt_log.ign_notice_f "Received %d bytes from %s: %s" length (Client.to_string client) command;
      callback client (if (String.length command) > 1 then command else ""); (* for `nc` probe packets *)
      loop ()
    in loop ()

  let init server =
(*
    Lwt_log.default := Lwt_log.syslog
      ~facility:`Daemon
      ~template:"$(name)[$(pid)]: $(message)" ();
*)
    Lwt_engine.on_timer 60. true (fun _ ->
      Lwt_log.ign_info "Processed no requests in the last minute.") |> ignore; (* TODO *)
    Lwt_unix.on_signal Sys.sigint (fun _ -> Lwt_unix.cancel_jobs (); exit 0) |> ignore;
    Lwt_main.at_exit (fun () -> Lwt_log.notice "Shutting down...");
    Lwt_log.ign_notice "Starting up...";
    let udp_socket = UDP.Socket.bind udp_interface udp_port in
    Lwt_log.ign_notice_f "Listening at udp://%s:%d." udp_interface udp_port;
    Lwt.async (fun () -> recv_command udp_socket (evaluate server));
    server

  let loop server =
    fst (Lwt.wait ())
end

let main options config_path =
  if String.is_empty config_path
  then `Error (true, "no configuration file specified")
  else `Ok (Lwt_main.run (Server.create config_path |> Server.init |> Server.loop))

(* Options common to all commands *)

let common_options debug verbosity = { debug; verbosity }

let common_options_term =
  let debug =
    let doc = "Enable debugging output." in
    Arg.(value & flag & info ["debug"] ~doc)
  in
  let verbosity =
    let doc = "Suppress informational output." in
    let quiet = Quiet, Arg.info ["q"; "quiet"] ~doc in
    let doc = "Give verbose output." in
    let verbose = Verbose, Arg.info ["v"; "verbose"] ~doc in
    Arg.(last & vflag_all [Normal] [quiet; verbose])
  in
  Term.(const common_options $ debug $ verbosity)

(* Command definitions *)

let command =
  let config_path =
    let doc = "A file path to a configuration script." in
    Arg.(value & pos 0 string "" & info [] ~docv:"CONFIG" ~doc)
  in
  let doc = "Conreality daemon." in
  let man = man_sections in
  Term.(ret (const main $ common_options_term $ config_path)),
  Term.info "conreald" ~version ~doc ~man

let () =
  match Term.eval command with `Error _ -> exit 1 | _  -> exit 0
