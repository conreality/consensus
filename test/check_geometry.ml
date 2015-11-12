(* This is free and unencumbered software released into the public domain. *)

open Consensus.Geometry

let float =
  let module M = struct
    type t = float
    (*let equal = ( = )*)
    let equal a b = (Printf.sprintf "%f" a) = (Printf.sprintf "%f" b)
    let pp = Format.pp_print_float
  end in
  (module M: Alcotest.TESTABLE with type t = M.t)

let todo () = Alcotest.(check bool) "PASS" true true
let of_floats l = List.map string_of_float l

let e = 2.71828
let pi = 3.14159
let phi = 1.61803

let tvec3_1 = V3.create 3. 1. 2.
let tvec3_1opposite = V3.create ( -3. ) ( -1. ) ( -2. )
let tvec3_2 = V3.create e pi phi
let tvec3_0 = V3.zero

let v3_create () = Alcotest.(check (list float)) "float list" [e; pi; phi] ([(V3.x tvec3_2); (V3.y tvec3_2); (V3.z tvec3_2)])
let v3_x () = Alcotest.(check float) "same float" 3. (V3.x tvec3_1)
let v3_y () = Alcotest.(check float) "same float" 3.14159 (V3.y tvec3_2)
let v3_z () = Alcotest.(check float) "same float" 2. (V3.z tvec3_1)
let v3_el () = Alcotest.(check int) "same int" 3 (int_of_float (V3.x tvec3_1))
let v3_zero () = Alcotest.(check (list float)) "float list" [0.; 0.; 0.] ([V3.x tvec3_0; V3.y tvec3_0; V3.z tvec3_0])
let v3_unitx () = Alcotest.(check bool) "same bool" true (V3.eq V3.unitx (V3.create 1. 0. 0.))
let v3_unity () = Alcotest.(check bool) "same bool" true (V3.eq V3.unity (V3.create 0. 1. 0.))
let v3_unitz () = Alcotest.(check bool) "same bool" true (V3.eq V3.unitz (V3.create 0. 0. 1.))
let v3_invert () = Alcotest.(check bool) "same bool" true (V3.eq tvec3_1opposite (V3.invert tvec3_1))
let v3_neg () = Alcotest.(check bool) "same bool" true (V3.eq tvec3_1opposite (V3.neg tvec3_1))
let v3_add () = let v = V3.add tvec3_1 tvec3_2 in Alcotest.(check (list float)) "float list" [5.71828; 4.14159; 3.61803] ([(V3.x v); (V3.y v); (V3.z v)])
let v3_op_add () = let v = V3.( + ) tvec3_1 tvec3_2 in Alcotest.(check (list float)) "float list" [5.71828; 4.14159; 3.61803] ([(V3.x v); (V3.y v); (V3.z v)])
(* doesn't work with sprintf, works with string_of_float
let v3_sub () = let v = V3.sub tvec3_1 tvec3_2 in Alcotest.(check (list float)) "float list" [0.28172; -2.14159; 0.38197] ([(V3.x v); (V3.y v); (V3.z v)])
*)
let v3_sub () = let v = V3.sub tvec3_1 tvec3_2 in Alcotest.(check (list string)) "string list" ["0.28172"; "-2.14159"; "0.38197"] (of_floats [(V3.x v); (V3.y v); (V3.z v)])
let v3_sub2 () = let v = V3.sub tvec3_1 tvec3_1 in Alcotest.(check (list float)) "float list" [0.; 0.; 0.] ([V3.x v; V3.y v; V3.z v])
let v3_op_sub () = let v = V3.( - ) tvec3_1 tvec3_2 in Alcotest.(check (list string)) "string list" ["0.28172"; "-2.14159"; "0.38197"] (of_floats [(V3.x v); (V3.y v); (V3.z v)])
let v3_eq () = Alcotest.(check bool) "same bool" true (V3.eq V3.zero V3.zero)
let v3_op_eq () = Alcotest.(check bool) "same bool" true (V3.eq V3.zero  V3.zero)
let v3_float_equals () = Alcotest.(check float) "same float" e (V3.x tvec3_2)
let v3_smul () = let v = V3.smul tvec3_1 2. in Alcotest.(check (list float)) "float list" [6.; 2.; 4.] ([(V3.x v); (V3.y v); (V3.z v)])
let v3_op_smul () = todo ()
let v3_opposite () = Alcotest.(check bool) "same bool" true (V3.opposite tvec3_1 tvec3_1opposite)
let v3_opposite_failure () = Alcotest.(check bool) "same bool" false (V3.opposite tvec3_1 tvec3_2)
let v3_dotproduct () = Alcotest.(check float) "same float" 14.53249 (V3.dotproduct tvec3_1 tvec3_2)
let v3_dotproduct2 () = Alcotest.(check float) "same float" 14. (V3.dotproduct tvec3_1 tvec3_1)
(* TODO: Implement a second test using tvec3_1 and tvec2_3 *)
(* crosstproduct = < a2b3 - a3b2, a3b1 - a1b3, a1b2 - a2b1 > *)
let v3_crossproduct () = let v = V3.crossproduct tvec3_1 tvec3_1 in Alcotest.(check (list float)) "float list" [0.; 0.; 0.] ([(V3.x v); (V3.y v); (V3.z v)])
let v3_magnitude () = Alcotest.(check float) "same float" 3.741657387 (V3.magnitude tvec3_1)
let v3_magnitude2 () = Alcotest.(check float) "same float" 14. (V3.magnitude2 tvec3_1)
let v3_normalize () = todo ()
let v3_distance () = todo ()

(* This is how we do multiple tests per function. Note the semicolons! *)
let v3_laborious_floats () =
  Alcotest.(check float) "same float" e (V3.x tvec3_2);
  Alcotest.(check float) "same float" pi (V3.y tvec3_2);
  Alcotest.(check float) "same float" phi (V3.z tvec3_2)

let () =
  Alcotest.run "My first test" [
    "test_set", [
      "v3 create",               `Quick, v3_create;
      "v3 x",                    `Quick, v3_x;
      "v3 y",                    `Quick, v3_y;
      "v3 z",                    `Quick, v3_z;
      "v3 element",              `Quick, v3_el;
      "v3 zero",                 `Quick, v3_zero;
      "v3 unitx",                `Quick, v3_unitx;
      "v3 unity",                `Quick, v3_unity;
      "v3 unitz",                `Quick, v3_unitz;
      "v3 invert",               `Quick, v3_invert;
      "v3 neg",                  `Quick, v3_neg;
      "v3 add",                  `Quick, v3_add;
      "v3 op_add",               `Quick, v3_op_add;
      "v3 sub",                  `Quick, v3_sub;
      "v3 sub2",                 `Quick, v3_sub2;
      "v3 op_sub",               `Quick, v3_op_sub;
      "v3 eq",                   `Quick, v3_eq;
      "v3 op_eq",                `Quick, v3_op_eq;
      "v3 float equality",       `Quick, v3_float_equals;
      "v3 smul",                 `Quick, v3_smul;
      "v3 op_smul",              `Quick, v3_op_smul;
      "v3 opposite",             `Quick, v3_opposite;
      "v3 opposite failure",     `Quick, v3_opposite_failure;
      "v3 dot product",          `Quick, v3_dotproduct;
      "v3 dot product2",         `Quick, v3_dotproduct2;
      "v3 cross product",        `Quick, v3_crossproduct;
      "v3 magnitude",            `Quick, v3_magnitude;
      "v3 magnitude2",           `Quick, v3_magnitude2;
      "v3 normalize",            `Quick, v3_normalize;
      "v3 distance",             `Quick, v3_distance;
      "v3 laborious floats",     `Quick, v3_laborious_floats;
    ];
  ]

