(* This is free and unencumbered software released into the public domain. *)

open Ocamlbuild_plugin
open Command

let cxx = "c++" (*find_command ["clang++"; "g++"; "c++"]*)

let stdlib_dir = lazy begin
  let ocamlc_where = !Options.build_dir / (Pathname.mk "ocamlc.where") in
  let () = Command.execute ~quiet:true (Cmd(S[!Options.ocamlc; A"-where"; Sh">"; P ocamlc_where])) in
  String.chomp (read_file ocamlc_where)
end

let () =
  dispatch begin function

  | Before_options ->
    Options.use_ocamlfind := true

  | After_rules ->
    ocaml_lib ~extern:true "opencv_core";
    ocaml_lib ~extern:true "opencv_objdetect";

    dep  ["file:src/consensus/prelude.ml"]
         ["src/consensus/prelude/bool.ml";
          "src/consensus/prelude/char.ml";
          "src/consensus/prelude/float.ml";
          "src/consensus/prelude/int.ml";
          "src/consensus/prelude/math.ml";
          "src/consensus/prelude/string.ml"];

    dep  ["file:src/consensus/prelude.mli"]
         ["src/consensus/prelude/bool.mli";
          "src/consensus/prelude/char.mli";
          "src/consensus/prelude/float.mli";
          "src/consensus/prelude/int.mli";
          "src/consensus/prelude/math.mli";
          "src/consensus/prelude/string.mli"];

    dep  ["file:src/consensus/machinery.ml"]
         ["src/consensus/machinery/bcm2835.ml";
          "src/consensus/machinery/bcm2836.ml";
          "src/consensus/machinery/device.ml";
          "src/consensus/machinery/driver.ml";
          "src/consensus/machinery/gpio.ml";
          "src/consensus/machinery/sysfs.ml";
          "src/consensus/machinery/usb.ml"];

    dep  ["file:src/consensus/machinery.mli"]
         ["src/consensus/machinery/bcm2835.mli";
          "src/consensus/machinery/bcm2836.mli";
          "src/consensus/machinery/device.mli";
          "src/consensus/machinery/driver.mli";
          "src/consensus/machinery/gpio.mli";
          "src/consensus/machinery/sysfs.mli";
          "src/consensus/machinery/usb.mli"];

    dep  ["file:src/consensus/messaging.ml"]
         ["src/consensus/messaging/irc.ml";
          "src/consensus/messaging/mqtt.ml";
          "src/consensus/messaging/ros.ml";
          "src/consensus/messaging/stomp.ml";
          "src/consensus/messaging/topic.ml"];

    dep  ["file:src/consensus/messaging.mli"]
         ["src/consensus/messaging/irc.mli";
          "src/consensus/messaging/mqtt.mli";
          "src/consensus/messaging/ros.mli";
          "src/consensus/messaging/stomp.mli";
          "src/consensus/messaging/topic.mli"];

    dep  ["file:src/consensus/scripting.ml"]
         ["src/consensus/scripting/context.ml"];

    dep  ["file:src/consensus/scripting.mli"]
         ["src/consensus/scripting/context.mli"];

    dep  ["link"; "ocaml"; "use_vision"] ["src/consensus/libconsensus-vision.a"];

    flag ["link"; "ocaml"; "library"; "byte"; "use_vision"]
      (S[A"-dllib"; A"-lconsensus-vision";
         A"-cclib"; A"src/consensus/libconsensus-vision.a"]);

    flag ["link"; "ocaml"; "library"; "native"; "use_vision"]
      (S[A"-cclib"; A"src/consensus/libconsensus-vision.a"]);

    flag ["link"; "ocaml"; "program"; "byte"; "use_vision"]
      (S[A"-dllpath"; A"_build/src/consensus";
         A"-dllib"; A"-lconsensus-vision";
         A"-cclib"; A"src/consensus/libconsensus-vision.a"]);

    flag ["link"; "ocaml"; "program"; "native"; "use_vision"]
      (S[A"-cclib"; A"-rdynamic";
         A"-cclib"; A"-Wl,--whole-archive";
         A"-cclib"; A"src/consensus/libconsensus-vision.a";
         A"-cclib"; A"-Wl,--no-whole-archive"]);

    rule "ocaml C++ stubs: cc -> o"
      ~prod:"%.o"
      ~dep:"%.cc"
      begin fun env _build ->
        let cc = env "%.cc" in
        let o = env "%.o" in
        let tags = tags_of_pathname cc ++ "c++" ++ "compile" in
        Cmd(S[A cxx; T tags; A"-c"; A"-I"; A !*stdlib_dir; A"-fPIC"; A"-o"; P o; Px cc])
      end

  | _ -> ()
  end
